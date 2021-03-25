using RefJpeg

open("ac_codes.bin", "w") do io
    # Each row is a new run, starting from 0
    # Each column is a new size, starting from 1
    ac_table = collect(zip(RefJpeg.ac_lens, RefJpeg.ac_codes))

    for csize = 0:size(ac_table)[2]
        for run = 0:size(ac_table)[1]-1
            len, code = nothing, nothing
            if csize == 0
                if run == 0
                    len = length(RefJpeg.ac_eob)
                    code = join(RefJpeg.ac_eob, "")
                    code = repeat("0", (16 - len)) * code
                elseif run == 0xf
                    len = length(RefJpeg.ac_zrl)
                    code = join(RefJpeg.ac_zrl, "")
                    code = repeat("0", (16 - len)) * code
                else
                    len = 0
                    code = join(repeat([0], 16), "")
                end
            else
                len, code = ac_table[run+1, csize]
                code = reverse(digits(code, base=2, pad=16))
                code = join(code, "")
            end
            
            len = join(reverse(digits(len, base=2, pad=5)), "")
            # println("run: ", run, ", size: ", csize, ": ", len, code)
            println(io, len, code)
        end
    end
end

open("dc_codes.bin", "w") do io
    for word = RefJpeg.dc_words
        wordlen = length(word)
        pad = 16 - wordlen
        word = [repeat([0], pad); word]
        len_bin = reverse(digits(wordlen, base=2, pad=5))
        println(io, join([len_bin; word], ""))
    end
end
