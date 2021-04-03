using Images, FileIO, Printf
include("RefJpeg/src/RefJpeg.jl")


# full_img = load(download("https://www.ubc.ca/_assets/img/about-ubc/about_ubc-1200x438.jpg"))
x, y = 105, 385
w, h = 16, 16
img = Gray.(full_img[y:y+(h-1), x:x+(w-1)])
imgint = Int.(255 .* img .- 127)

blocks = RefJpeg.img_blocks(imgint)

@printf "Input:\n"
for blockrow = eachrow(blocks)
    for block = blockrow
        @printf "'{\n"
        for row = eachrow(block)
            @printf "  "
            for col = row
                @printf "%3d, " col
            end
            @printf "\n"
        end
        @printf "},\n"
    end
end

out = []
RefJpeg.encode_scan(out, img)

# dc, runs = RefJpeg.runlength_encode(RefJpeg.quantize(RefJpeg.dct2_2d_approx(imgint)))
# display(dc)
# display(runs)

# prev_dc = 0
# for blockrow = eachrow(blocks)
#     for block = blockrow
#         dc, runs = RefJpeg.runlength_encode(RefJpeg.quantize(RefJpeg.dct2_2d_approx(block)))
#         println("dc: ", dc)
#         display(runs)
#     end
# end

# display(out)
