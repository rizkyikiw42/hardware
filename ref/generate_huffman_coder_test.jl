using RefJpeg, Images, FileIO, Printf

function ones_encode_int(val)
    code = val
    if code < 0
        code = UInt16(-code)
        code = ~code & 0x3ff
    end
    code
end

# full_img = load(download("https://www.ubc.ca/_assets/img/about-ubc/about_ubc-1200x438.jpg"))
x, y = 105, 385
img = Gray.(full_img[y:y+7, x:x+7])

inblock = RefJpeg.quantize(RefJpeg.dct2(img))
dc, acs = RefJpeg.runlength_encode(inblock)

outbits = BitArray([])
RefJpeg.huffman_encode(0, dc, acs, outbits)

@printf "dc: %d\n" dc
@printf "acs:\n{\n"

for ac = acs
    if ac == :eob
        @printf "  '{ 0, 0, 'x },\n"
    elseif ac == :zrl
        @printf "  '{ 15, 0, 'x },\n"
    else
        run, val = ac
        size = length(RefJpeg.ones_encode(val))
        code = ones_encode_int(val)
        @printf "  '{ %d, %d, 10'h%03x },\n" run size code
    end
end

@printf "}\n"

@printf "out:\n"
@printf "{\n"

for i = 1:16:length(outbits)
    chunk = outbits[i:min(i+15, length(outbits))]
    chunk = [chunk; repeat([0], 16 - length(chunk))]
    @printf "  16'b%s,\n" join(Int8.(chunk), "")
end

@printf "}"
