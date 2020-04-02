function post(alg::ASB07,
              ivp::IVP{<:AbstractContinuousSystem},
              tspan;
              kwargs...)

    @unpack δ, approx_model, max_order = alg

    if haskey(kwargs, :NSTEPS)
        NSTEPS = kwargs[:NSTEPS]
        T = NSTEPS * δ
    else
        # get time horizon from the time span imposing that it is of the form (0, T)
        T = _get_T(tspan, check_zero=true, check_positive=true)
        NSTEPS = ceil(Int, T / δ)
    end

    # normalize system to canonical form
    # x' = Ax, x in X
    # x' = Ax + u, x in X, u in U
    ivp_norm = _normalize(ivp)

    # discretize system
    ivp_discr = discretize(ivp_norm, δ, approx_model)
    Φ = state_matrix(ivp_discr)
    Ω0 = initial_state(ivp_discr)
    X = stateset(ivp_discr)

    # this algorithm requires Ω0 to be a zonotope
    Ω0 = _convert_or_overapproximate(Zonotope, Ω0)
    Ω0 = _reduce_order(Ω0, max_order)
    c0 = center(Ω0)
    G0 = genmat(Ω0)
    N = eltype(Ω0)

    # true <=> there is no input, i.e. the system is of the form
    # x' = Ax, x ∈ X
    got_homogeneous = !hasinput(ivp_discr)

    if haskey(kwargs, :force_static) && kwargs[:force_static]
        error("no implemented yet")
        n = size(Φ, 1)
        p = size(G0, 2) # number of generators
        Φ = SMatrix{n, n, N, n*n}(Φ)
        c0_st = SVector{n, N}(c0)
        G0_st = SMatrix{n, p, N, n*p}(G0)
        Ω0 = Zonotope(c0_st, G0_st)

    elseif isa(G0, Diagonal)
        c0 = Vector(c0)
        G0 = Matrix(G0)
        Ω0 = Zonotope(c0, G0)
    end

    # preallocate output flowpipe
    ZT = typeof(Ω0)
    F = Vector{ReachSet{N, ZT}}(undef, NSTEPS)

    if got_homogeneous
        reach_homog_ASB07!(F, Ω0, Φ, NSTEPS, δ, max_order, X)
    else
        error("not implemented yet")
        U = inputset(ivp_discr)
        if isa(U, LazySet)
            U = _convert_or_overapproximate(Zonotope, U)
            reach_inhomog_ASB07!(F, Ω0, Φ, NSTEPS, δ, max_order, X, U)
        else
            error("inputs of type $(typeof(U)) cannot be handled yet")
        end
    end

    return Flowpipe(F)
end