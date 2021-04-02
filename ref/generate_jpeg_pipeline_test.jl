using RefJpeg, Images, FileIO, Printf

# full_img = load(download("https://www.ubc.ca/_assets/img/about-ubc/about_ubc-1200x438.jpg"))
x, y = 105, 385
img = Gray.(full_img[y:y+7, x:x+7])
imgint = Int.(255 .* img .- 127)

@printf "Input:\n"
for row = eachrow(imgint)
    for col = row
        @printf "%3d, " col
    end
    @printf "\n"
end

out = []
RefJpeg.encode_scan(out, img)

dc, runs = RefJpeg.runlength_encode(RefJpeg.quantize(RefJpeg.dct2_2d_approx(imgint)))
display(dc)
display(runs)

display(out)
