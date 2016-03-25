///
module rxd.meta2.lambda;

// BUG: after DMD bug 11886 is fixed, the `State` parameter,
// the `state` member and the static if can be removed.
struct Lambda(alias fun, State...)
{
    State state;

    auto opCall(A...)(A args)
    {
        return fun(state, args);
    }

    static if (State.length)
    {
        @disable this();
        this (State s) { this.state = s; }
    }
}

///
auto λ(alias fun, State...)(State state)
{
    static if (State.length)
        return Lambda!(fun, State)(state);
    else
        return Lambda!(fun).init;
}

///
unittest
{
    auto increment = λ!(x => x + 1);

    assert (increment(1) == 2);
    assert (increment(1.0) == 2.0);
}
