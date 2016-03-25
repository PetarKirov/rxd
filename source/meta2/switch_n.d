///
module rxd.meta2.switch_n;

import std.format : format;

///
enum switch2(string pred, string action1, string action2) =
q{
    static if (__traits(compiles, { enum b = %1$s; } ))
    {
        static if (%1$s)
            %2$s
        else
            %3$s
    }
    else
    {
        if (%1$s)
            %2$s
        else
            %3$s
    }
}.format(pred, action1, action2);

///
unittest
{
    static assert (switch2!("val", "return 1;", "return 2;") ==
    q{
    static if (__traits(compiles, { enum b = val; } ))
    {
        static if (val)
            return 1;
        else
            return 2;
    }
    else
    {
        if (val)
            return 1;
        else
            return 2;
    }
});

}

///
enum switch3(string pred, string action1, string action2, string action3) =
q{
    static if (__traits(compiles, { enum b = %1$s; } ))
    {
        static if (%1$s)
            %2$s
        else
            %3$s
    }
    else
    {
        %4$s
    }
}.format(pred, action1, action2, action3);

///
unittest
{
    int func(bool val)
    {
        mixin (switch3!("val", "return 1;", "return 2;", "return 3;"));
    }

    assert (func(true) == 3);
    assert (func(false) == 3);

    int func2(bool val)()
    {
        mixin (switch3!("val", "return 1;", "return 2;", "return 3;"));
    }

    assert (func2!true == 1);
    assert (func2!false == 2);
}


///
enum switch4(string pred, string do1, string do2, string do3, string do4) =
q{
    static if (__traits(compiles, { enum b = %1$s; } ))
    {
        static if (%1$s)
            %2$s
        else
            %3$s
    }
    else
    {
        if (%1$s)
            %4$s
        else
            %5$s
    }
}.format(pred, do1, do2, do3, do4);

///
unittest
{
    int func(bool val)
    {
        mixin (switch4!("val",
                    "return 1;", "return 2;",
                    "return 3;", "return 4;"));
    }

    assert (func(true) == 3);
    assert (func(false) == 4);

    int func2(bool val)()
    {
        mixin (switch4!("val",
                    "return 1;", "return 2;",
                    "return 3;", "return 4;"));
    }

    assert (func2!true == 1);
    assert (func2!false == 2);
}

