using RefJpeg

scaled_qtab = Int.(round.(RefJpeg.q_table ./ RefJpeg.scalesm))'

open("q_table.hex", "w") do io
    for row = eachrow(scaled_qtab)
        for q = row
            write(io, string(q, base=16, pad=3), " ")
        end
        write(io, "\n")
    end
end
