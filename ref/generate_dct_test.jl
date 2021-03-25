# using RefJpeg
include("RefJpeg/src/RefJpeg.jl")

A = [ 65  84  88   74   71   84   91   86;
      89  82  80   87   91   86   76   69;
      91  80  69   62   51   37   29   28;
      41  39  26    9    6   13   11    1;
       4  -1  -6    2   21   25   -3  -38;
       0  -2  14   38   33   -9  -56  -82;
      11  19  32   30   -9  -61  -83  -77;
      49  49  29  -15  -61  -81  -73  -58  ]

display(A)

display(Int.(round.(RefJpeg.dct2(A))))
display(Int.(round.(RefJpeg.dct2_2d_approx_ns(A))))
