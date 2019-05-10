export generate_test_problems, generate_noisy_data

"""

This dictionary represents the list of models used in the generation of random tests.
Return the tuple `(n, model, model_str)`, where

  - `n` is the number of parameters of the model
  - `model` is the model of the form `m(x, θ)`, where `x` are the
    variables and `θ` are the parameters
  - `model_str` is the string representing the model, used to build random generated problems

"""
const model_list = Dict(
    "linear" => (2, (x, θ) -> θ[1] * x[1] + θ[2],
                 "(x, θ) -> θ[1] * x[1] + θ[2]"),
    "cubic" => (4, (x, θ) -> θ[1] * x[1]^3 + θ[2] * x[1]^2 + θ[3] * x[1] + θ[4],
                "(x, θ) -> θ[1] * x[1]^3 + θ[2] * x[1]^2 + θ[3] * x[1] + θ[4]"),
    "expon" => (3, (x, θ) -> θ[1] + θ[2] * exp(- θ[3] * x[1]),
                "(x, θ) -> θ[1] + θ[2] * exp(- θ[3] * x[1])"),
    "logistic" => (4, (x, θ) -> θ[1] + θ[2] / (1.0 + exp(- θ[3] * x[1] + θ[4])),
                   "(x, θ) -> θ[1] + θ[2] / (1.0 + exp(- θ[3] * x[1] + θ[4]))"),
    "circle" => (3, (x, θ) -> (x[1] - θ[1])^2 + (x[2] - θ[2])^2 - θ[3]^2,
                 "(x, θ) -> (x[1] - θ[1])^2 + (x[2] - θ[2])^2 - θ[3]^2")
)


"""

    generate_test_problems(datFilename::String, solFilename::String,
                         model::Function, modelStr::String, n::Int,
                         np::Int, p::Int)

Generate random data files for testing fitting problems.

  - `datFilename` and `solFilename` are strings with the name of the
    files for storing the random data and solution, respectively.
  - `model` is the model function and `modelStr` is a string
    representing this model function, e.g.

         model = (x, θ) -> θ[1] * x[1] + θ[2]
         modelStr = "(x, θ) -> θ[1] * x[1] + θ[2]"

    where vector `θ` represents the parameters (to be found) of the
    model and vector `x` are the variables of the model.
  - `n` is the number of parameters
  - `np` is the number of points to be generated.
  - `p` is the number of trusted points to be used in the LOVO
    approach.

"""
function generate_test_problems(datFilename::String,
                              solFilename::String, model::Function,
                              modelStr::String,
                              n::Int, np::Int, p::Int;
                              xMin=-10.0, xMax=10.0,
                              θSol=10.0 * randn(n), std=200.0, outTimes=7.0)

    # Generate solution file
    
    open(solFilename, "w") do sol
    
        println(sol, n) # number of variables

        println(sol, θSol) # parameters
        
        println(sol, modelStr) # function expression

    end

    # Generate data file
    
    open(datFilename, "w") do data
    
        vdata, θsol, outliers = generate_noisy_data(model, n, np, p;
                                   xMin=xMin, xMax=xMax, θSol=θSol,
                                   std=std, outTimes=outTimes)
    
        # Dimension of the domain of the function to fit
        @printf(data, "%d\n", 1)

        for k = 1:np

            @printf(data, "%20.15f %20.15f %1d\n",
                    vdata[k, 1], vdata[k, 2], Int(k in outliers))

        end

    end
    
end

"""

    get_unique_random_points(np::Int, npp::Int)

Choose exactly `npp` unique random points from a set containing `np`
points. This function is similar to `rand(vector)`, but does not allow
repetitions.

Return a vector with the selected points.

"""
function get_unique_random_points(np::Int, npp::Int)

    # Check invalid arguments
    ((np <= 0) || (npp <=0)) && (return Vector{Int}())

    ntp = min(npp, np)
    
    v = Vector{Int}(undef, ntp)

    points = [1:np;]

    while ntp > 0
        
        u = rand(points, ntp)

        unique!(u)

        for i in u
            v[ntp] = i
            ntp -= 1
        end

        setdiff!(points, u)
        
    end

    return v

end

"""

    generate_noisy_data(model::Function, n::Int, np::Int, p::Int;
                      xMin::Float64=-10.0, xMax::Float64=10.0,
                      θSol::Vector{Float64}=10.0 * randn(Float64, n),
                      std::Float64=200.0, outTimes::Float64=7.0)

    generate_noisy_data(model::Function, n, np, p, xMin::Float64, xMax::Float64)

    generate_noisy_data(model::Function, n::Int, np::Int, p::Int,
                      θSol::Vector{Float64}, xMin::Float64, xMax::Float64)

Random generate a fitting one-dimensional data problem.

This function receives a `model(x, θ)` function, the number of parameters
`n`, the number of points `np` to be generated and the number of
trusted points `p`. 

If the `n`-dimensional vector `θSol` is provided, then the exact
solution will not be random generated. The interval `[xMin, xMax]` for
generating the values to evaluate `model` can also be provided.

It returns a tuple `(data, θSol, outliers)` where

  - `data`: (`np` x `2`) array, where each row contains `x` and
    `model(x, θSol)`.
  - `θSol`: `n`-dimensional vector with the exact solution.
  - `outliers`: the outliers of this data set

"""
function generate_noisy_data(model::Function, n::Int, np::Int, p::Int;
                           xMin::Float64=-10.0, xMax::Float64=10.0,
                           θSol::Vector{Float64}=10.0 * randn(Float64, n),
                           std::Float64=200.0, outTimes::Float64=7.0)

    @assert(xMin <= xMax, "Invalid interval for random number generation")
    
    # Generate (xi,yi) where xMin <= x_i <= xMax (data)
    x = [xMin:(xMax - xMin) / (np - 1):xMax;]
    
    data = Array{Float64}(undef, np, 3)

    # Points selected to be outliers
    v = get_unique_random_points(np, np - p)
    
    # Add noise to some random points
    for k = 1:np
            
        y = model(x[k], θSol) + randn() * std

        noise = 0.0
            
        if k in v 
            y = model(x[k], θSol)
            noise = outTimes * std * sign(randn())
        end
            
        data[k, 1] = x[k]
        data[k, 2] = y + noise
        data[k, 3] = noise

    end

    return data, θSol, v

end

generate_noisy_data(model::Function, n::Int, np::Int, p::Int, xMin::Float64, xMax::Float64) =
    generate_noisy_data(model, n, np, p; xMin=xMin, xMax=xMax)

generate_noisy_data(model::Function, n::Int, np::Int, p::Int,
                  θSol::Vector{Float64}, xMin::Float64, xMax::Float64) =
                      generate_noisy_data(model, n, np, p; xMin=xMin, xMax=xMax, θSol=θSol)
