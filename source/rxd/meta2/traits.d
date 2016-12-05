///
module rxd.meta2.traits;

///
//enum allConvertible(alias from, alias to) =
//    allConvertible!(typeof(from), typeof(to));

///
template allConvertible(From, To)
{
    import rxd.meta2.type : isType, isAliasTuple;
    static if (!isType!From && !isAliasTuple!From &&
               !isType!To   && !isAliasTuple!To)
        enum allConvertible = is(From : To);

    else static if (isType!From)
        enum allConvertible = allConvertible!(From.typeOf, To);

    else static if (isType!To)
        enum allConvertible = allConvertible!(From, To.typeOf);

    else static if (isAliasTuple!From && isAliasTuple!To)
    {
        static if (From.typeTypeSeq.length != To.typeTypeSeq.length)
            enum allConvertible = false;

        else static if (From.typeTypeSeq.length == 0)
            enum allConvertible = true;

        else
            enum allConvertible =
                allConvertible!(
                        From.init.front.typeOf,
                        To.init.front.typeOf
                ) &&
                allConvertible!(
                        typeof(From.init.dropOne()),
                        typeof(To.init.dropOne())
                );
    }

    else
        static assert (0, "Unsupported types: " ~ From.stringof ~ " -> " ~
                To.stringof);

}

alias Func(RT, Args...) = RT function(Args);

/// Checks if `Model`'s parameter types are convertible to `Func`'s
/// parameter types and `Func`'s return type can be converted
/// to Model's return type.
template isFuncLike(Func, Model)
{
    import std.traits : ReturnType, Parameters, isImplicitlyConvertible;
    import rxd.meta2.type : AliasTuple, TypeSeq;

    enum isFuncLike =
        is(ReturnType!Func : ReturnType!Model) &&
        allConvertible!(
            AliasTuple!(TypeSeq!(Parameters!Model)),
            AliasTuple!(TypeSeq!(Parameters!Func)));
}

///
unittest
{
    struct S
    {
        int   f1(int)   { return 0; }
        float f2(int)   { return 0; }
        int   f3(float) { return 0; }
        float f4(float) { return 0; }
    }

    static assert ( isFuncLike!(typeof(&S.f1), Func!(int, int)));
    static assert (!isFuncLike!(typeof(&S.f2), Func!(int, int)));
    static assert ( isFuncLike!(typeof(&S.f3), Func!(int, int)));
    static assert (!isFuncLike!(typeof(&S.f4), Func!(int, int)));

    static assert ( isFuncLike!(typeof(&S.f1), Func!(float, int)));
    static assert ( isFuncLike!(typeof(&S.f2), Func!(float, int)));
    static assert ( isFuncLike!(typeof(&S.f3), Func!(float, int)));
    static assert ( isFuncLike!(typeof(&S.f4), Func!(float, int)));

    static assert (!isFuncLike!(typeof(&S.f1), Func!(int, float)));
    static assert (!isFuncLike!(typeof(&S.f2), Func!(int, float)));
    static assert ( isFuncLike!(typeof(&S.f3), Func!(int, float)));
    static assert (!isFuncLike!(typeof(&S.f4), Func!(int, float)));

    static assert (!isFuncLike!(typeof(&S.f1), Func!(float, float)));
    static assert (!isFuncLike!(typeof(&S.f2), Func!(float, float)));
    static assert ( isFuncLike!(typeof(&S.f3), Func!(float, float)));
    static assert ( isFuncLike!(typeof(&S.f4), Func!(float, float)));
}

unittest
{
    class Person {}
    class Employee : Person {}

    Person   g1(Person)   { return null; }
    Person   g2(Employee) { return null; }
    Person   g3(Object)   { return null; }
    Employee g4(Person)   { return null; }
    Employee g5(Employee) { return null; }
    Employee g6(Object)   { return null; }
    Object   g7(Person)   { return null; }
    Object   g8(Employee) { return null; }
    Object   g9(Object)   { return null; }


}
