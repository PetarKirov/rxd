///
module rxd.meta2.closure;

import rxd.meta2.traits : isEnumValue;

struct Closure(Args...)
{
    pragma (msg, "In Closure template: ", Args.stringof);

    enum gennedCode = genArgsAliases!Args("Args");
    pragma (msg, gennedCode);
    mixin (gennedCode);

    alias use = typeof(this);
    private alias __my__args__ = Args;
}

///
unittest
{
    struct Point { float x, y; }

    int a = 34;
    Point b = { 3, 4 };
    int c = 32;
    enum d = 42;

    auto inner = Closure!(c, d)();
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

private string genArgsAliases(Args...)(string prefix = "Args")
{
    //enum string prefix = "Args";

    import std.conv : to;
    import std.format : format;
    import std.typecons : staticIota;
    string res;

    pragma (msg, "In genArgsAliases -> ", Args.stringof);

    string genAliasFunc(string name, string start, size_t idx)
    {
        //pragma (msg, "In genAliasFunc -> name: ", name, " start: ", start,
        //        " idx: ", idx);

        return ("    auto ref __get__%1$s() { return %2$s[%3$s]; }\n" ~
                "    alias %1$s = __get__%1$s;\n")
            .format(name, start, idx);
    }

    foreach (idx; staticIota!(0, Args.length))
        static if (isEnumValue!(Args[idx]))
            res ~= "    enum %s = %s[%s];\n"
                .format(__traits(identifier, Args[idx]), prefix, idx);

        else static if (is(typeof(Args[idx]) : Closure!U, U...))
            res ~= genArgsAliases!(Args[idx].__my__args__)(
                "%s[%s].__my__args__".format(prefix, idx));

        else
            res ~= genAliasFunc(Args[idx].stringof, prefix, idx);

    return res;
}
