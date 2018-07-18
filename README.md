# Exposition

Quite frequently I've wanted to show people various fractals I've made and discovered. This usually translates into
showing them some pictures on my phone that I made 3 years ago, showing them google results, or building and
running a preview app with different equations and iteration methods.

Exposition is a showcase of fractals. Some are interactive, which allows you to see how the fractal changes over 
fields of complex numbers. There is a cursor which shows where in the complex plain the parameters is, click or
drag to adjust it's location.

The app is written in Swift, and a bit of C++ for the shader code. The fractals are computed on the GPU using 
Metal 2. You can use guestures to scroll and zoom, and when you get lost click on View -> Reset. Finally, there's 
also Touch Bar support 😉.

## Building

Exposition runs on macOS High Sierra 10.13 (released in late 2017). It might work on previous versions but I haven't
tested it.

## Samples
### The Mandelbrot Set
![Mandelbrot Set](https://raw.githubusercontent.com/Mrwerdo/Exposition/master/Samples/MandelbrotSet.png)
### Julia Sets
![Julia Sets](https://raw.githubusercontent.com/Mrwerdo/Exposition/master/Samples/JuliaSet.png)
### Roots of z cubed equals 1
![Roots of z cubed equals 1](https://raw.githubusercontent.com/Mrwerdo/Exposition/master/Samples/ZCubed1.png)
![Roots of z cubed equals 1](https://raw.githubusercontent.com/Mrwerdo/Exposition/master/Samples/ZCubed2.png)
![Roots of z cubed equals 1](https://raw.githubusercontent.com/Mrwerdo/Exposition/master/Samples/ZCubed3.png)
### Cosine
![Cosine](https://raw.githubusercontent.com/Mrwerdo/Exposition/master/Samples/Cosine1.png)
![Cosine](https://raw.githubusercontent.com/Mrwerdo/Exposition/master/Samples/Cosine2.png)
### Square root of z
![Square Root](https://raw.githubusercontent.com/Mrwerdo/Exposition/master/Samples/SquareRoot.png)
