function post(alg::LGG09{N, AM, VN, TN}, ivp::IVP{<:AbstractContinuousSystem}, tspan;
              time_shift::N=zero(N), kwargs...) where {N, AM, VN, TN}

    @unpack δ, approx_model, template, static, threaded = alg

    if haskey(kwargs, :NSTEPS)
        NSTEPS = kwargs[:NSTEPS]
        T = NSTEPS * δ
    else
        # get time horizon from the time span imposing that it is of the form (0, T)
        T = _get_T(tspan, check_zero=true, check_positive=true)
        NSTEPS = ceil(Int, T / δ)
    end

    # normalize system to canonical form
    ivp_norm = _normalize(ivp)

    # discretize system
    ivp_discr = discretize(ivp_norm, δ, approx_model)
    Φ = state_matrix(ivp_discr)
    Ω₀ = initial_state(ivp_discr)
    X = stateset(ivp_discr)

    if alg.sparse # ad-hoc conversion of Φ to sparse representation
        Φ = sparse(Φ)
    end

    cacheval = Val(alg.cache)

    # true <=> there is no input, i.e. the system is of the form x' = Ax, x ∈ X
    got_homogeneous = !hasinput(ivp_discr)

    # NOTE: option :static currently ignored!

    # preallocate output flowpipe
    SN = SubArray{N, 1, Matrix{N}, Tuple{Base.Slice{Base.OneTo{Int}}, Int}, true}
    RT = TemplateReachSet{N, VN, TN, SN}
    F = Vector{RT}(undef, NSTEPS)

    if got_homogeneous
        ρℓ = reach_homog_LGG09!(F, template, Ω₀, Φ, NSTEPS, δ, X, time_shift, cacheval)
    else
        U = inputset(ivp_discr)
        @assert isa(U, LazySet)
        ρℓ = reach_inhomog_LGG09!(F, template, Ω₀, Φ, NSTEPS, δ, X, U, time_shift, cacheval)
    end

    return Flowpipe(F, Dict{Symbol, Any}(:sfmat => ρℓ))
end
