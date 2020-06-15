@taylorize function vanderPol!(dx, x, params, t)
    local μ = 1.0
    dx[1] = x[2]
    dx[2] = (μ * x[2]) * (1 - x[1]^2) - x[1]
    return dx
end

function vanderpol()
    # set of initial states
    X0 = Hyperrectangle(low=[1.25, 2.35], high=[1.55, 2.45])

    # initial-value problem
    ivp = @ivp(x' = vanderPol!(x), dim: 2, x(0) ∈ X0)

    # time horizon
    tspan = (0.0, 5.0)

    return ivp, tspan
end

