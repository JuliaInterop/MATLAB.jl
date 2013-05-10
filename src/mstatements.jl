# functions to convert Julia expression to MATLAB statement strings

mstatement(s::Symbol) = string(s)

function write_mstatement(io::IO, s)
    print(io, string(s))
end

function write_mstatement(io::IO, s::ASCIIString)
    print(io, "'")
    print(io, s)
    print(io, "'")
end

function write_mstatement(io::IO, s::Char)
    print(io, "'")
    print(io, string(s))
    print(io, "'")
end


const matlab_infix_ops = Set(
    :+, :-, :*, :/, :\, :^,
    :.+, :.-, :.*, :./, :.\, :.^,
    :|, :&)


function write_mstatement(io::IO, ex::Expr)
    h = ex.head
    a = ex.args
    na = length(a)

    if h == :(=)
        write_mstatement(io, a[1])
        print(io, " = ")
        write_mstatement(io, a[2])

    elseif h == (:call)
        f = a[1]

        if na == 1
            write_mstatement(io, f)
            print(io, "()")

        elseif na == 2
            write_mstatement(io, f)
            print(io, "(")
            write_mstatement(io, a[2])
            print(io, ")")

        elseif na == 3
            if has(matlab_infix_ops, f)
                print(io, "(")
                write_mstatement(io, a[2])
                print(io, ") ")
                write_mstatement(io, f)
                print(io, " (")
                write_mstatement(io, a[3])
                print(io, ")")
            else
                write_mstatement(io, f)
                print(io, "(")
                write_mstatement(io, a[2])
                print(io, ", ")
                write_mstatement(io, a[3])
                print(io, ")")
            end

        else
            write_mstatement(io, f)
            print(io, "(")
            for i = 2 : na - 1
                write_mstatement(io, a[i])
                print(io, ", ")
            end
            write_mstatement(io, a[na])
            print(io, ")")
        end

    elseif h == :vcat || h == :hcat || h == :row || h == :tuple || h == :cell1d
        print(io, h == :cell1d ? "{" : "[")
        if na > 0
            sep = h == :vcat ? "; " : ", "
            for i = 1 : na-1
                write_mstatement(io, a[i])
                print(io, sep)
            end
            write_mstatement(io, a[na])
        end
        print(io, h == :cell1d ? "}" : "]")

    elseif h == :cell2d
        print(io, "{")
        if na > 0
            rows = a[1]
            cols = a[2]
            for i = 1:rows
                if i != 1
                    print(io, "; ")
                end
                for j = 0:cols-1
                    if j != 0
                        print(io, " ")
                    end
                    write_mstatement(io, a[2+j*rows+i])
                end
            end
        end
        print(io, "}")

    elseif h == :curly
        write_mstatement(io, a[1])
        print(io, "{")
        for i = 2 : na - 1
            write_mstatement(io, a[i])
            print(io, ", ")
        end
        write_mstatement(io, a[na])
        print(io, "}")

    elseif h == :. 
        write_mstatement(io, a[1])
        print(io, ".")
        print(io, string(eval(a[2])))

    elseif h == :(:)
        write_mstatement(io, a[1])
        for i = 2:na
            print(io, ":")
            write_mstatement(io, a[i])
        end

    elseif h == symbol("'") || h == symbol(".'")
        print(io, "(")
        write_mstatement(io, a[1])
        print(io, ")")
        print(io, string(h))

    elseif h == :block
        for s in a
            write_mstatement(io, s)
            print(io, "\n")
        end

    elseif h == :line
        nothing # ignore line numbers

    else
        error("Expression $(ex) is not recognized by mstatement.")
    end
end

function mstatement(ex::Expr)
    ss = IOBuffer()
    write_mstatement(ss, ex)
    bytestring(ss)
end
