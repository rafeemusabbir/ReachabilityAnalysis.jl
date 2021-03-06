@testset "TMJets algorithm" begin
    prob, tspan = vanderpol()

    # default algorithm for nonlinear systems
    sol = solve(prob, tspan=tspan)
    @test sol.alg isa TMJets

    # pass the algorithm explicitly
    sol = solve(prob, tspan=tspan, TMJets())
    @test sol.alg isa TMJets

    # pass options outside algorithm
    sol = solve(prob, T=0.2, max_steps=2100)
    @test sol.alg isa TMJets && sol.alg.max_steps == 2100
    sol = solve(prob, T=0.2, maxsteps=2100) # alias
    @test sol.alg isa TMJets && sol.alg.max_steps == 2100
    sol = solve(prob, T=0.2, orderT=7, orderQ=1)
    @test sol.alg isa TMJets && sol.alg.orderT == 7 && sol.alg.orderQ == 1
    sol = solve(prob, T=0.2, abs_tol=1e-11)
    @test sol.alg isa TMJets && sol.alg.abs_tol == 1e-11
    sol = solve(prob, T=0.2, abstol=1e-11)
    @test sol.alg isa TMJets && sol.alg.abs_tol == 1e-11

    # split initial conditions
    X0, S = initial_state(prob), system(prob)
    X0s = split(X0, [2, 1]) # split along direction x
    sols = solve(IVP(S, X0s), T=0.1, threading=false) # no threading
    @test flowpipe(sols) isa MixedFlowpipe

    sols = solve(IVP(S, X0s), T=0.1, threading=true) # with threading (default)
    @test flowpipe(sols) isa MixedFlowpipe
end

@testset "TMJets algorithm: linear IVPs" begin
    prob, tspan = exponential_1d()
    sol = solve(prob, tspan=tspan, TMJets())
    @test sol.alg isa TMJets

    # test intersection with invariant
    prob, tspan = exponential_1d(invariant=HalfSpace([-1.0], -0.3)) # x >= 0.3
    sol_inv = solve(prob, tspan=tspan, TMJets())
    @test [0.3] ∈ overapproximate(sol_inv[end], Zonotope)
    m = length(sol_inv)
    # check that the following reach-set escapes the invariant
    @test [0.3] ∉ overapproximate(sol[m+1], Zonotope)

    # TODO test higher order system
#    prob, tspan = linear5D_homog()
#    sol = solve(prob, tspan=tspan, TMJets())
#    @test sol.alg isa TMJets

    # TODO test linear system with input
#    prob, tspan = linear5D()
#    sol = solve(prob, tspan=tspan, TMJets())
#    @test sol.alg isa TMJets
end

#=
alg = TMJets(abs_tol=1e-10, orderT=10, orderQ=2)

# reach mode
sol = solve(P, T=7.0, alg)
@test set(sol[1]) isa Hyperrectangle # check default set representation
=#
