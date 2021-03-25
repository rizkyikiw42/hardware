package sim_dct;
   localparam real PI = $acos(-1);

   localparam real M1 = $cos(4 * PI / 16);
   localparam real M2 = $cos(6 * PI / 16);
   localparam real M3 = $cos(2 * PI / 16) - $cos(6 * PI / 16);
   localparam real M4 = $cos(2 * PI / 16) + $cos(6 * PI / 16);

   typedef real vec8[8];

   function vec8 dct_approx(int a[8]);
      real b[8], c[8], d[9], e[9], f[8], S[8];
      b[0] = a[0] + a[7];
      b[1] = a[1] + a[6];
      b[2] = a[3] - a[4];
      b[3] = a[1] - a[6];
      b[4] = a[2] + a[5];
      b[5] = a[3] + a[4];
      b[6] = a[2] - a[5];
      b[7] = a[0] - a[7];

      c[0] = b[0] + b[5];
      c[1] = b[1] - b[4];
      c[2] = b[2] + b[6];
      c[3] = b[1] + b[4];
      c[4] = b[0] - b[5];
      c[5] = b[3] + b[7];
      c[6] = b[3] + b[6];
      c[7] = b[7];

      d[0] = c[0] + c[3];
      d[1] = c[0] - c[3];
      d[2] = c[2];
      d[3] = c[1] + c[4];
      d[4] = c[2] - c[5];
      d[5] = c[4];
      d[6] = c[5];
      d[7] = c[6];
      d[8] = c[7];

      e[0] = d[0];
      e[1] = d[1];
      e[2] = int'(M3 * d[2]);
      e[3] = int'(M1 * d[7]);
      e[4] = int'(M4 * d[6]);
      e[5] = d[5];
      e[6] = int'(M1 * d[3]);
      e[7] = int'(M2 * d[4]);
      e[8] = d[8];

      f[0] = e[0];
      f[1] = e[1];
      f[2] = e[5] + e[6];
      f[3] = e[5] - e[6];
      f[4] = e[3] + e[8];
      f[5] = e[8] - e[3];
      f[6] = e[2] + e[7];
      f[7] = e[4] + e[7];

      S[0] = f[0];
      S[1] = f[4] + f[7];
      S[2] = f[2];
      S[3] = f[5] - f[6];
      S[4] = f[1];
      S[5] = f[5] + f[6];
      S[6] = f[3];
      S[7] = f[4] - f[7];

      return S;
   endfunction // dct_definition
endpackage
