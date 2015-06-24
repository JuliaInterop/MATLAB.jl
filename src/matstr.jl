# Syntax for mat"" string interpolation

# A really basic parser intended only to handle checking whether
# a variable is on the left or right hand side of an expression
type DumbParserState
    paren_depth::Int
    in_string::Bool
end
DumbParserState() = DumbParserState(0, false)

# Returns true if an = is encountered and updates pstate
function dumb_parse!(pstate::DumbParserState, str::String)
    paren_depth = pstate.paren_depth
    in_string = pstate.in_string
    x = '\0'
    s = start(str)
    while !done(str, s)
        lastx = x
        (x, s) = next(str, s)
        if in_string
            if x == '\''
                if !done(str, s) && next(str, s)[1] == '\''
                    (x, s) = next(str, s)
                else
                    in_string = false
                end
            end
        else
            if x == '('
                paren_depth += 1
            elseif x == ')'
                paren_depth -= 1
            elseif x == '\'' && lastx in ",( \t\0;"
                in_string = true
            elseif x == '=' && !(lastx in "<>~")
                if !done(str, s) && next(str, s)[1] == '='
                    (x, s) = next(str, s)
                else
                    return true
                end
            elseif x == '%'
                break
            end
        end
    end
    pstate.paren_depth = paren_depth
    pstate.in_string = in_string
    return false
end

# Check if a given variable is assigned, used, or both. Returns the#
# assignment and use status
function check_assignment(interp, i)
    # Go back to the last newline
    before = String[]
    for j = i-1:-1:1
        if isa(interp[j], String)
            sp = split(interp[j], "\n")
            unshift!(before, sp[end])
            for k = length(sp)-1:-1:1
                match(r"\.\.\.[ \t]*\r?$", sp[k]) == nothing && @goto done_before
                unshift!(before, sp[k])
            end
        end
    end
    @label done_before

    # Check if this reference is inside parens at the start, or on the rhs of an assignment
    pstate = DumbParserState()
    (dumb_parse!(pstate, join(before)) || pstate.paren_depth > 1) && return (false, true)

    # Go until the next newline or comment
    after = String[]
    both_sides = false
    for j = i+1:length(interp)
        if isa(interp[j], String)
            sp = split(interp[j], "\n")
            push!(after, sp[1])
            for k = 2:length(sp)
                match(r"\.\.\.[ \t]*\r?$", sp[k-1]) == nothing && @goto done_after
                push!(after, sp[k])
            end
        elseif interp[j] == interp[i]
            both_sides = true
        end
    end
    @label done_after

    assigned = dumb_parse!(pstate, join(after))
    used = !assigned || both_sides || (i < length(interp) && match(r"^[ \t]*\(", interp[i+1]) != nothing)
    return (assigned, used)
end

function do_mat_str(ex)
    # Hack to do interpolation
    interp = parse(string("\"\"\"", replace(ex, "\"\"\"", "\\\"\"\""), "\"\"\""))
    if isa(interp, String)
        interp = [interp]
    elseif interp.head == :string
        interp = interp.args
    elseif interp.head == :macrocall
        interp = interp.args[2:end]
    else
        throw(ArgumentError("unexpected input"))
    end

    # Handle interpolated variables
    putblock = Expr(:block)
    getblock = Expr(:block)
    usedvars = Set{Symbol}()
    assignedvars = Set{Symbol}()
    varmap = Dict{Symbol,Symbol}()
    for i = 1:length(interp)
        if !isa(interp[i], String)
            # Don't put the same symbol to MATLAB twice
            if haskey(varmap, interp[i])
                var = varmap[interp[i]]
            else
                var = symbol(string("matlab_jl_", i))
                if isa(interp[i], Symbol)
                    varmap[interp[i]] = var
                end
            end

            # Try to determine if variable is being used in an assignment
            (assigned, used) = check_assignment(interp, i)

            if used && !(var in usedvars)
                push!(usedvars, var)
                (var in assignedvars) || push!(putblock.args, :(put_variable($(Meta.quot(var)), $(esc(interp[i])))))
            end
            if assigned && !(var in assignedvars)
                push!(assignedvars, var)
                push!(getblock.args, Expr(:(=), esc(interp[i]), :(get_variable($(Meta.quot(var))))))
            end

            interp[i] = var
        end
    end

    # Clear `ans` and set `matlab_jl_has_ans` before we run the code
    unshift!(interp, "clear ans;\nmatlab_jl_has_ans = 0;\n")

    # Add a semicolon to the end of the last statement to suppress output
    isa(interp[end], String) && (interp[end] = rstrip(interp[end]))
    push!(interp, ";")

    # Figure out if `ans` exists in code to avoid an error if it doesn't
    push!(interp, "\nmatlab_jl_has_ans = exist('ans', 'var');")

    quote
        $(putblock)
        eval_string($(join(interp)))
        $(getblock)
        $(if !isempty(usedvars) || !isempty(assignedvars)
            # Clear variables we created
            :(eval_string($(string("clear ", join(union(usedvars, assignedvars), " "), ";"))))
        end)
        if get_variable(:matlab_jl_has_ans) != 0
            # Return ans if it was set
            get_variable(:ans)
        end
    end
end

macro mat_str(ex)
    do_mat_str(ex)
end

# Only needed for Julia 0.3
macro mat_mstr(ex)
    do_mat_str(ex)
end
