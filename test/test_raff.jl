@testset "Simple tests" begin

    model(x, θ) = θ[1] * exp(x[1] * θ[2])

    gmodel!(g, x, θ) = begin

        g[1] = exp(x[1] * θ[2])
        g[2] = x[1] * θ[1] * exp(x[1] * θ[2])

    end

    @testset "Basic usage" begin
    
        data = [-1.0  3.2974425414002564;
                -0.75 2.9099828292364025;
                -0.5   2.568050833375483;
                -0.25 2.2662969061336526;
                0.0                  2.0;
                0.25   1.764993805169191;
                0.5   1.5576015661428098;
                0.75  1.5745785575819442; #noise
                1.0   1.2130613194252668;
                1.25  1.0705228570379806;
                1.5   0.9447331054820294;
                1.75  0.8337240393570168;
                2.0   0.7357588823428847;
                2.25  0.6493049347166995;
                2.5   0.5730095937203802;
                2.75  0.5056791916094929;
                3.0  0.44626032029685964;
                3.25  0.5938233504083881; #noise 
                3.5   0.3475478869008902;
                3.75 0.30670993368985694;
                4.0   0.5706705664732254; #noise
                ]

        answer = [2.0, -0.5]

        θ = [0.0, 0.0]

        rout = lmlovo(model, θ, data, 2, 18)

        @test rout.status == 1
        @test rout.solution ≈ answer atol=1.0e-5
        @test rout.p == 18
        
        θ = [0.0, 0.0]

        # Test with small p
        rout = lmlovo(model, θ, data, 2, 3)

        @test rout.status == 1
        @test rout.p == 3

        θ = [0.0, 0.0]

        rout = raff(model, data, 2)
        
        @test rout.f ≈ 0.0 atol=1.0e-5
        @test rout.solution ≈ answer atol=1.0e-5
        @test rout.p == 18

        @test_throws AssertionError lmlovo(model, θ, data, 0, 1)
        @test_throws AssertionError lmlovo(model, θ, data, 2, -1)

        rout = lmlovo(model, θ, data, 2, 0)

        @test rout.status == 1
        @test rout.iter == 0
        @test rout.f == 0
        @test rout.outliers == [1:size(data)[1];]
        @test rout.solution == θ

        # lmlovo with function and gradient

        θ = [0.0, 0.0]

        rout = lmlovo(model, gmodel!, θ, data, 2, 18)
        
        @test rout.status == 1
        @test rout.solution ≈ answer atol=1.0e-5
        @test rout.p == 18

        θ = [0.0, 0.0]

        rout = raff(model, gmodel!, data, 2)
        
        @test rout.f ≈ 0.0 atol=1.0e-5
        @test rout.solution ≈ answer atol=1.0e-5
        @test rout.p == 18

        @test_throws AssertionError lmlovo(model, gmodel!, θ, data, 0, 1)
        @test_throws AssertionError lmlovo(model, gmodel!, θ, data, 2, -1)

        rout = lmlovo(model, gmodel!, θ, data, 2, 0)

        @test rout.status == 1
        @test rout.iter == 0
        @test rout.f == 0
        @test rout.outliers == [1:size(data)[1];]
        @test rout.solution == θ

    end

    # Test to check Issue #1
    
    @testset "Error in printing" begin

        m(x, θ) = θ[1] * x[1]^2 + θ[2]

        A = [ -2.0  5.00;
              -1.5  3.25;
              -1.0  2.00;
              -0.5  1.25;
              0.0  1.00;
              0.5  1.25;
              1.0  2.00;
              1.5  3.25;
              2.0  5.00 ]

        θ = [0.0, 0.0]

        # Changes log just for this test
        rout = with_logger(Logging.NullLogger()) do
            
            lmlovo(m, θ, A, 2, 4)

        end

        @test rout.status == 1
        @test rout.p == 4
        
    end

    @testset "Test parameters" begin

        data = [-1.0   3.2974425414002564;
                -0.75  2.9099828292364025;
                -0.5    2.568050833375483;
                -0.25  2.2662969061336526;
                 0.0                  2.0;
                 0.25   1.764993805169191;
                 0.5   1.5576015661428098;
                 0.75  1.5745785575819442; #noise
                 1.0   1.2130613194252668;
                 1.25  1.0705228570379806;
                 1.5   0.9447331054820294;
                 1.75  0.8337240393570168;
                 2.0   0.7357588823428847;
                 2.25  0.6493049347166995;
                 2.5   0.5730095937203802;
                 2.75  0.5056791916094929;
                 3.0  0.44626032029685964;
                 3.25  0.5938233504083881; #noise 
                 3.5   0.3475478869008902;
                 3.75 0.30670993368985694;
                 4.0   0.5706705664732254; #noise
                ]

        answer = [2.0, -0.5]
        
        rout = raff(model, gmodel!, data, 2; noutliers=0)
        
        @test rout.p == 21
        
        rout = raff(model, data, 2; noutliers=5)
        
        @test rout.f ≈ 0.0 atol=1.0e-5
        @test rout.solution ≈ answer atol=1.0e-5
        @test rout.p == 18

        rout = raff(model, data, 2; ftrusted=(21 - 5)/21)

        @test rout.f ≈ 0.0 atol=1.0e-5
        @test rout.solution ≈ answer atol=1.0e-5
        @test rout.p == 18

        rout = raff(model, data, 2; ftrusted=(18/21, 18/21))

        @test rout.f ≈ 0.0 atol=1.0e-5
        @test rout.solution ≈ answer atol=1.0e-5
        @test rout.p == 18
        
        @test raff(model, data, 2; ftrusted=(0.5, 1.1)) == RAFFOutput()
        @test raff(model, data, 2; ftrusted=-0.1) == RAFFOutput()
        
    end

    # Tests for RAFFOutput
    
    @testset "RAFFOutput tests" begin

        nullOut = RAFFOutput(0, [], -1, 0, Inf, [])
        
        @test RAFFOutput() == nullOut

        @test RAFFOutput(0) == nullOut

        nullPOut = RAFFOutput(0, [], -1, 10, Inf, [])

        @test nullPOut == RAFFOutput(10)
        
    end

end
