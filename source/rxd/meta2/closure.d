///
module rxd.meta2.closure;

struct Closure(Args...)
{
    pragma (msg, "In Closure template: ", Args.stringof);

    enum gennedCode = genArgsAliases!Args("Args");
    pragma (msg, gennedCode);
    mixin (gennedCode);

    alias use = typeof(this);
    private alias __my__args__ = Args;
}

private string genArgsAliases(Args...)(string _)
{
    enum string prefix = "Args";

    import std.conv : to;
    import std.format : format;
    import std.typecons : staticIota;
    string res;

    pragma (msg, "In genArgsAliases -> ", Args.stringof);
    pragma (msg, "In genArgsAliases -> ", is(typeof(Args[0])));

    string genAliasFunc(string name, string start, size_t idx)()
    {
        pragma (msg, "In genAliasFunc -> name: ", name, " start: ", start,
                " idx: ", idx);

        return ("    auto ref __get__%1$s() { return %2$s[%3$s]; }\n" ~
                "    alias %1$s = __get__%1$s;\n")
            .format(name, start, idx);
    }

    foreach (idx; staticIota!(0, Args.length))
        static if (is(typeof(Args[idx]) : Closure!U, U...))
            foreach (idx2; staticIota!(0, Args[idx].__my__args__.length))
                res ~= genAliasFunc!(Args[idx].__my__args__[idx2].stringof,
                            "Args[" ~ idx.to!string ~"].__my__args__", idx2);
        else
            res ~= genAliasFunc!(Args[idx].stringof, prefix, idx);

    return res;
}

unittest
{
    struct Point { float x, y; }

    int a = 34;
    Point b = { 3, 4 };
    int c = 32;

    auto inner = Closure!(c)();
    auto outer = Closure!(inner, a, b)();

    static assert (inner.sizeof >= (void*).sizeof);
    static assert (outer.sizeof >= (void*).sizeof);

    assert (inner.c == 32);
    assert (outer.a == 34);
    assert (outer.b == Point(3, 4));
    assert (outer.c == 32);

    outer.a++;
    assert (a == 35);
    assert (outer.a == 35);

    outer.c++;
    assert (c == 33);
    assert (inner.c == 33);
    assert (outer.c == 33);

    void someFunc(C)(C closure)
    {
        assert (closure.a == 35);

        with (closure)
            assert (a == 35);

        int local = 85;
        auto ctx = Closure!(closure, local)();

        assert (ctx.local == 85);
        assert (ctx.a == 35);
    }

    someFunc(outer);
}
