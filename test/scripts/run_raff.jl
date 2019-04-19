using RAFF
using DelimitedFiles
using Printf

# Set Debug for Logging
using Logging
using Base.CoreLogging

function run_raff(maxms=1, initguess=nothing)
    
    n, model, modelstr = RAFF.model_list["logistic"]

    open("/tmp/output.txt") do fp
        
        global N = parse(Int, readline(fp))
        
        global data = readdlm(fp)
        
    end

    if initguess == nothing

        initguess = zeros(Float64, n)

    end

    rsol = raff(model, data[:, 1:end - 1], n; MAXMS=maxms, initguess=initguess, ε=1.0e-6)
    
    @printf("Solution found:
            fbest = %f
            p     = %d\n", rsol.f, rsol.p)
    println(rsol.solution)

    return rsol

end
