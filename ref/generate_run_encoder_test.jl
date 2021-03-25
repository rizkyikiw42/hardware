using RefJpeg, Images, FileIO, Printf

full_img = load(download("https://www.ubc.ca/_assets/img/about-ubc/about_ubc-1200x438.jpg"))
x, y = 105, 385
img = Gray.(full_img[y:y+7, x:x+7])

inblock = RefJpeg.quantize(RefJpeg.dct2(img))
inblock_zigzag = collect(RefJpeg.ZigZagIter(inblock))

println("Zigzag coefficients: \n{")
for (i, c) = enumerate(inblock_zigzag)
    if i % 8 == 1
        print("  ")
    end
    @printf "%2d, " c
    if i % 8 == 0
        println()
    end
end
print("}\n\n")

function ones_encode_int(val)
    code = val
    if code < 0
        code = UInt16(-code)
        code = ~code & 0x3ff
    end
    code
end

dc, acs = RefJpeg.runlength_encode(inblock)
println("Output runs:\n{")

dc_size = length(RefJpeg.ones_encode(dc))
dc_code = ones_encode_int(dc)
@printf "  '{ 0, %d, 10'h%003x },\n" dc_size dc_code

for symbol = acs
    print("  ")

    if symbol == :zrl
        run = 15
        size = 0
        code = "'x"
    elseif symbol == :eob
        run = 0
        size = 0
        code = "'x"
    else
        run, val = symbol
        size = length(RefJpeg.ones_encode(val))
        code = ones_encode_int(val)
        code = @sprintf "10'h%03x" code
    end

    @printf "'{ %d, %d, %s },\n" run size code
end
println("}")
