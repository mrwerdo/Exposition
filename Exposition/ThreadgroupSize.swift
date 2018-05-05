//
//  ThreadgroupSize.swift
//  Exposition
//
//  Created by Andrew Thompson on 5/5/18.
//  Copyright © 2018 Andrew Thompson. All rights reserved.
//

import Metal

extension MTLSize
{
    var hasZeroDimension: Bool {
        return depth == 0 || width == 0 || height == 0
    }
}

public struct ThreadgroupSizes
{
    var threadsPerThreadgroup: MTLSize
    var threadgroupsPerGrid: MTLSize
    
    public static let zeros = ThreadgroupSizes(
        threadsPerThreadgroup: MTLSize(),
        threadgroupsPerGrid: MTLSize())
    
    var hasZeroDimension: Bool {
        return threadsPerThreadgroup.hasZeroDimension || threadgroupsPerGrid.hasZeroDimension
    }
}

public extension MTLComputePipelineState
{
    /// Selects "reasonable" values for threadsPerThreadgroup and threadgroupsPerGrid for the given `drawableSize`.
    /// - Remark: The heuristics used here are not perfect. There are many ways to underutilize the GPU,
    /// including selecting suboptimal threadgroup sizes, or branching in the shader code.
    ///
    /// If you are certain you can always use threadgroups with a multiple of `threadExecutionWidth`
    /// threads, then you may want to use MTLComputePipleineDescriptor and its property
    /// `threadGroupSizeIsMultipleOfThreadExecutionWidth` to configure your pipeline state.
    ///
    /// If your shader is doing some more interesting calculations, and your threads need to share memory in some
    /// meaningful way, then you’ll probably want to do something less generalized to choose your threadgroups.
    func threadgroupSizesForDrawableSize(_ drawableSize: CGSize) -> ThreadgroupSizes
    {
        let waveSize = self.threadExecutionWidth
        let maxThreadsPerGroup = self.maxTotalThreadsPerThreadgroup
        
        let drawableWidth = Int(drawableSize.width)
        let drawableHeight = Int(drawableSize.height)
        
        if drawableWidth == 0 || drawableHeight == 0 {
            print("drawableSize is zero")
            return .zeros
        }
        
        // Determine the set of possible sizes (not exceeding maxThreadsPerGroup).
        var candidates: [ThreadgroupSizes] = []
        for groupWidth in 1...maxThreadsPerGroup {
            for groupHeight in 1...(maxThreadsPerGroup/groupWidth) {
                // Round up the number of groups to ensure the entire drawable size is covered.
                // <http://stackoverflow.com/a/2745086/23649>
                let groupsPerGrid = MTLSize(width: (drawableWidth + groupWidth - 1) / groupWidth,
                                            height: (drawableHeight + groupHeight - 1) / groupHeight,
                                            depth: 1)
                
                candidates.append(ThreadgroupSizes(
                    threadsPerThreadgroup: MTLSize(width: groupWidth, height: groupHeight, depth: 1),
                    threadgroupsPerGrid: groupsPerGrid))
            }
        }
        
        /// Make a rough approximation for how much compute power will be "wasted" (e.g. when the total number
        /// of threads in a group isn’t an even multiple of `threadExecutionWidth`, or when the total number of
        /// threads being dispatched exceeds the drawable size). Smaller is better.
        func _estimatedUnderutilization(_ s: ThreadgroupSizes) -> Int {
            let excessWidth = s.threadsPerThreadgroup.width * s.threadgroupsPerGrid.width - drawableWidth
            let excessHeight = s.threadsPerThreadgroup.height * s.threadgroupsPerGrid.height - drawableHeight
            
            let totalThreadsPerGroup = s.threadsPerThreadgroup.width * s.threadsPerThreadgroup.height
            let totalGroups = s.threadgroupsPerGrid.width * s.threadgroupsPerGrid.height
            
            let excessArea = excessWidth * drawableHeight + excessHeight * drawableWidth + excessWidth * excessHeight
            let excessThreadsPerGroup = (waveSize - totalThreadsPerGroup % waveSize) % waveSize
            
            return excessArea + excessThreadsPerGroup * totalGroups
        }
        
        // Choose the threadgroup sizes which waste the least amount of execution time/power.
        let result = candidates.min { _estimatedUnderutilization($0) < _estimatedUnderutilization($1) }
        return result ?? .zeros
    }
}

