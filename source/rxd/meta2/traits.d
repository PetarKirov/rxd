///
module rxd.meta2.traits;

enum isEnumValue(T...) = T.length == 1 &&
    __traits(compiles, { enum x = T[0]; });

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

import std.meta : Alias, AliasSeq;

/**
 * Applies the sequence of arguments `args` to the function or template `fun`
 * either as function or template arguments, at compile-time or at run-time
 * (if CTFE is not possible).
 *
 * `apply` is most likely to be found used as a building block in higher-order
 * templates and $(LREF AliasSeq) algorithms like $(LREF staticMap) which need
 * to call or instantiate (as appropriate) functions or templates, passed as
 * parameters.
 *
 * Params:
 *      fun  = function or template to call or instantiate
 *      args = template / function arguments to `apply` to `fun`
 *
 * Returns:
 *      An alias to `fun(args)` or `fun!(args)`
 */
template apply(alias func, args...)
{
    static if (__traits(compiles, { alias res = Alias!(func(args)); }))
        // Evaluate `fun(args)` at compile-time and wrap the result
        // in an `Alias`, so it can be used without special-casing
        // in higher-order templates like `staticMap`.
        alias apply = Alias!(func(args));

    else static if (is(typeof(func(args))))
        // `fun` is a regular callable, but we can't call it at compile-time.
        // Delay the evaluation of `fun(args)` to run-time by wrapping it in a
        // `@property` function.
        @property auto ref apply() { return func(args); }

    else static if (__traits(compiles, { alias res = Alias!(func!args); }))
        // `fun` is a manifest constant (a.k.a. `enum`) template or a
        // function template with no run-time parameters which can be evaulated
        // at compile-time. Wrap the result in an `Alias`, so it can be aliased.
        alias apply = Alias!(func!args);

    else static if (__traits(compiles, { alias res = func!args; }))
        // `fun` is template that yields an `AliasSeq`, or something that can't
        // be wrapped with `Alias`.
        alias apply = func!args;

    else
        static assert (0, "Cannot call / instantiate `" ~
            __traits(identifier, func) ~ "` with arguments: `" ~
            args.stringof ~ "`.");
}

/**
 * `apply` can call regular functions with arguments known either at
 * compile-time, or run-time:
 */
@safe pure nothrow @nogc
unittest
{
    int add(int a, int b) { return a + b; }
    enum int a = 2, b = 3;
    enum int sum = apply!(add, a, b);
    static assert(sum == 5);

    int x = 2, y = 5;
    int z = apply!((a, b) => a + b, x, y);
    assert(z == 7);

    // TODO: Show higher-order template example

    // When `apply` is used to call functions it returns the result
    // by reference (when possible):
    static struct S { int x; }
    static ref int getX(ref S s) { return s.x; }
    static int inc(ref int x) { return ++x; }
    auto s = S(41);
    int theAnswer = apply!(inc, apply!(getX, s));
    assert (theAnswer == 42);
    assert (s.x == 42);
}

/**
 * `apply` can also instantiate function templates with compile-time parameters
 * and alias or call them:
 */
@safe nothrow @nogc
unittest
{
    int mul(int a, int b)() { return a * b; }

    enum product = apply!(mul, 2, 7);
    static assert (product == 14);

    static int counter = 0;
    int offset(int x) { return 10 * ++counter + x; }
    alias offset7 = apply!(offset, 7);

    assert(offset7()         == 17);
    assert(apply!(offset, 7) == 27);
    assert(offset7()         == 37);
}

/// `apply` can instnatiate manifest constant (a.k.a. `enum`) templates:
@safe pure nothrow @nogc
unittest
{
    enum ulong square(uint x) = x * x;
    enum result = apply!(square, 3);
    static assert(result == 9);
}

/**
 * Two or more `apply` instances can be chained to provide the template and
 * later the run-time arguments of a function template:
 */
@safe pure nothrow @nogc
unittest
{
    static T[] transform(alias fun, T)(T[] arr)
    {
        foreach (ref e; arr)
            e = fun(e);
        return arr;
    }

    alias result = apply!(
        apply!(transform, x => x * x, int),
        [2, 3, 4, 5]);

    static assert (result == [4, 9, 16, 25]);
}

/// `apply` can instnatiate alias templates
@safe pure nothrow @nogc
unittest
{
    alias ArrayOf(T) = T[];
    alias ArrayType = apply!(ArrayOf, int);
    static assert (is(ArrayType == int[]));

    import std.traits : CommonType;
    alias Types = AliasSeq!(byte, short, int, long);
    static assert (is(apply!(CommonType, Types) == long));
}

/// `apply` can instnatiate higher-order templates that yield alias sequences:
@safe pure nothrow @nogc
unittest
{
    import std.meta : staticMap;

    alias ArrayOf(T) = T[];
    alias Types = AliasSeq!(byte, short, int, long);
    alias ArrayTypes = apply!(staticMap, ArrayOf, Types);
    static assert (is(ArrayTypes == AliasSeq!(byte[], short[], int[], long[])));

    template Overloads(T, string member)
    {
        alias Overloads = AliasSeq!(__traits(getOverloads, T, member));
    }

    struct S
    {
        static int use(int x) { return x + 1; }
        static bool use(char c) { return c >= '0' && c <= '9'; }
        static char use(string s) { return s[0]; }
    }

    static assert(apply!(Overloads, S, "use").length == 3);

    alias atIndex(size_t idx, List...) = Alias!(List[idx]);

    static assert(
        apply!(  // 3) call the function with the argument `10`
            apply!(  // 2) get the first element (with type `int use(int x)`)
                atIndex,
                0,
                apply!(Overloads, S, "use") // 1) get the `use` overload set
            ),
            10
        ) == 11);

    static assert(
        apply!(apply!(atIndex, 1, apply!(Overloads, S, "use")), '3') == true);

    alias useOverloadSet = Alias!(__traits(getOverloads, S, "use"))[0];
    alias useOverloadSet = Alias!(__traits(getOverloads, S, "use"))[1];
    alias useOverloadSet = Alias!(__traits(getOverloads, S, "use"))[2];

    static assert(useOverloadSet(41) == 42);
    //static assert(useOverloadSet('@') == false);
    //static assert(useOverloadSet('7') == true);
    static assert(useOverloadSet("Voldemort") == 'V');

    template AliasTuple(T...)
    {
        alias expand = T;
    }

    template applyN(alias fun, Tuples...)
        if (Tuples.length > 0)
    {
        static if (Tuples.length == 1)
            alias applyN = apply!(fun, Tuples[0].expand);
        else
            alias applyN = applyN!(
                apply!(fun, Tuples[0].expand),
                Tuples[1 .. $]);
    }

    //alias AT = AliasTuple;
    //applyN!(Overloads, AT!(S, "use"), atIndex, 2, "asd");
    //applyN!("use", ApplyLeft!(Overloads, S), ApplyLeft!(atIndex, 2)

    static assert(
        apply!(apply!(atIndex, 2, apply!(Overloads, S, "use")), "asd") == 'a');
}

version (unittest)
{
    template staticMap1(alias func, Args...) if (Args.length > 0)
    {
        static if (Args.length == 1)
            alias staticMap1 = func!(Args[0]);
        else
            alias staticMap1 = AliasSeq!(
                func!(Args[0]),
                staticMap1!(func, Args[1 .. $]));
    }

    template staticMap2(alias func, Args...) if (Args.length > 0)
    {
        static if (Args.length == 1)
            alias staticMap2 = apply!(func, Args[0]);
        else
            alias staticMap2 = AliasSeq!(
                apply!(func, Args[0]),
                staticMap2!(func, Args[1 .. $]));
    }
}

// Undcoumented, because `staticMap1` and `staticMap2` can't be defined inside
// the unittest.
@safe pure nothrow @nogc
unittest
{
    enum square(int x) = x * x;
    alias numbers = AliasSeq!(1, 2, 3);

    static assert (!__traits(compiles,
        { alias result = staticMap1!(x => x * x, numbers); }));

    alias result = staticMap2!(x => x * x, numbers);
    static assert([result] == [1, 4, 9]);
}

//template staticMapReduce(al


template allMatchFirst(alias pred, list...)
    if (list.length >= 2)
{
    //static if (is(typeof(pred(list[0], list[1])) : bool))
    //{
    //    static if (list.length == 2)
    //        bool allMatchFirst = pred(list[0], list[1]);

      //  else {}
            //bool allMatchFirst =
             //   allPairs(
    //}
    //else (is(typeof(pred!(list[0], list[1])): bool))
    //{
   // }
    //else
     //   static assert (0, "Can't call/instantiate pred with ", List.stringof);
}


template allPairs(alias pred, List...)
{
    alias first = List[0];
    alias rest = List[1 .. $];

    //static if (is(typeof(pred(List[0], List[1]))))



}

alias TypeOf(T) = T;
alias TypeOf(alias sym) = typeof(sym);

template sameFunctionSignature(alias F1, alias F2)
{
    import std.traits : isSomeFunction;

    enum bool sameFunctionSignature =
        isSomeFunction!F1 && isSomeFunction!F2 &&
        is(TypeOf!F1 == TypeOf!F2);
}

unittest
{
    import std.meta : AliasSeq;
    void f0(int x, int y);
    void f1(int x, int y);
    void f2(short x, short y);
    void f3(const int x, const int y);
    void f4(ref int x, ref int y);
    void f5(scope int x, scope int y);

    alias all = AliasSeq!(f1, f2, f3, f4, f5);

    //static foreach (idx, f1; all[0 .. $ - 1)
    //static foreach (f2; all[idx .. $])
    //static assert (sameFunctionSignature!(f0, f1));

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
