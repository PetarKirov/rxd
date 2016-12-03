///
module rxd.meta2.type;

import std.traits : isInstanceOf;

///
enum isType(T...) = T.length == 1 && is(T[0] : Type!U, U);

///
enum isAliasTuple(T) = isInstanceOf!(AliasTuple, T);

///
auto aliasTuple(Types...)(Types)
{
    return AliasTuple!Types();
}

template TypeSeq(T...)
{
    import std.meta : AliasSeq;
    static if (T.length == 0)
        alias TypeSeq = AliasSeq!();

    else
        alias TypeSeq = AliasSeq!(Type!(T[0]), TypeSeq!(T[1 .. $]));
}

///
auto val(T...)() if (T.length == 1)
{
    return Val!(T[0]).init;
}

///
struct Val(T...) if (T.length == 1)
{
    static assert (!is(T[0]),
        "Expected value, instead of type: " ~ T[0].stringof ~ "!");

    ///
    alias Type = typeof(T[0]);

    ///
    enum typeOf = type!Type;

    ///
    enum Type val = T[0];

    alias val this;
}

///
struct ValTuple(vals...)
{
    enum expand = vals;
}

///
auto type(T)()
{
    return Type!T.init;
}

/// ditto
struct Type(T)
{
    ///
    alias typeOf = T;

    const pure nothrow @safe @nogc:

    ///
    bool opEquals(U)(Type!U other)
    { return is(T == U); }

    ///
    auto opSlice()()
    { return Type!(T[]).init; }

    ///
    auto opIndex(S)(S sizeVal) if (is(S : Val!size, size_t size))
    { return Type!(T[sizeVal.val]).init; }

    ///
    auto opIndex(U)(Type!U keyType)
    { return Type!(T[keyType.typeOf]).init; }

    auto opBinary(string op, U)(Type!U other)
        if (op == "+" || op == "*")
    {
        import std.typecons : Tuple;
        import std.variant : Algebraic;

        static if (op == "+")
            return Type!(Algebraic!(T, U)).init;

        else static if (op == "*")
            return Type!(Tuple!(T, U)).init;

    }

    static if (is(typeOf == int))
    ///
    unittest
    {
        import std.typecons : Tuple;
        import std.variant : Algebraic;

        enum t1 = type!int;
        enum t2 = type!double;

        enum t3 = t1 + t2;
        static assert (t3 == type!(Algebraic!(int, double)));

        enum t4 = t1 * t2;
        static assert (t4 == type!(Tuple!(int, double)));

        enum t5 = (t1 + t2) * t1 + t4;
        static assert (t5 ==
            type!(
                Algebraic!(
                    Tuple!(
                        Algebraic!(int, double),
                        int
                    ),
                    Tuple!(int, double)
                )
            )
        );
    }

    ///
    auto unqualOf()
    {
        import std.traits : Unqual;
        return Type!(Unqual!T).init;
    }

    ///
    auto constOf()()
    { return Type!(const(T)).init; }

    ///
    auto immutableOf()()
    { return Type!(immutable(T)).init; }

    ///
    auto sharedOf()()
    { return Type!(shared(T)).init; }

    /// Convience function that forwards to std.traits.
    auto opDispatch(string traitName)()
    {
        import std.meta : AliasSeq;
        import std.traits;

        alias res = AliasSeq!(mixin(traitName ~ "!(this.typeOf)"));

        static if (res.length == 1 && is(typeof(res[0])))
            // Return values directly
            return res[0];

        else static if (res.length == 1 && is(res[0]))
            // Wrap types in Type(T)
            return type!res;

        else
            // Wrap value tuples in ValTuple
            return ValTuple!res.init;
    }

    static if (is(T == int))
    ///
    unittest
    {
        enum t1 = type!int;
        static assert (t1.opDispatch!"isIntegral");

        static assert ( type!float.isFloatingPoint);
        static assert (!type!float.isBoolean);

        enum t2 = type!string[type!int[]];
        static assert (t2 == type!(string[int[]]));
        static assert ( t2.isAssociativeArray);
        static assert (!t2.isArray);

        enum t3 = type!(byte*);
        static assert (t3.PointerTarget == type!byte);

        enum Names : string { n1 = "asd", n2 = "bfg" }
        enum t4 = type!Names;
        static assert (t4.OriginalType == type!string);
        enum members = t4.EnumMembers;
        static assert ([t4.EnumMembers.expand] == [Names.n1, Names.n2]);
    }

    ///
    string toString()
    {
        return typeof(this).stringof;
    }
}

unittest
{
    enum t1 = type!int;
    enum t2 = t1.constOf;
    enum t3 = t2.sharedOf;

    static assert (is(typeof(t1) == Type!int));
    static assert (is(t1.typeOf == int));
    static assert (is(typeof(t2) == Type!(const(int))));
    static assert (is(t3.typeOf == shared(const(int))));
    static assert (t3.unqualOf == t1);

    // operator opSlice() ( [] ) yields an array
    enum t4 = t1[];
    static assert (is(t4.typeOf == int[]));

    // can easily chain methods to generate complex types
    enum t5 = t1.immutableOf[].sharedOf;

    // operator opEquals(Type!U) ( == ) can be use check if two types
    // are the same
    static assert (t5 == type!(shared(immutable(int)[])));

    // operator opIndex(Type!U) ( e.g. [ Type!string ] ) can be used to
    // generate associative arrays
    enum t6 = t1[type!string];
    static assert (t6.isAssociativeArray);
    static assert (t6 == type!(int[string]));

    // operator opIndex(Val!size) ( e.g. [ Val!5 ] ) can be used to
    // generate static arrays
    enum t7 = t1[val!4];
    static assert (t7.isStaticArray);
    static assert (t7 == type!(int[4]));
}

///
struct AliasTuple(Types...)
{
    //Types expand;
    //alias expand this;
    alias typeOf = typeof(this);
    alias typeSeq = SeqFromTuple!(typeOf);
    alias typeTypeSeq = Types;

    enum empty = Types.length == 0;

    static if (empty)
    {
        // Special case allowing
        // ElementType!(typeof(this)) == TypeTuple!()
        // in generic code.

        auto front()() { return this; }
        auto back()() { return this; }
        auto dropOne()() { static assert (0); }
        auto dropBackOne()() { static assert (0); }
    }
    else
    {
        auto front()() { return Types[0].init; }
        auto back()() { return Types[$ - 1].init; }
        auto dropOne()() { return AliasTuple!(Types[1 .. $]).init; }
        auto dropBackOne()() { return AliasTuple!(Types[0 .. $ - 1]).init; }
    }

    string toString()
    {
        return typeOf.stringof;
    }
}

template SeqFromTuple(Tuple : AliasTuple!TL, TL...)
{
    import std.meta : AliasSeq;

    static if (TL.length == 0)
        alias SeqFromTuple = AliasSeq!();
    else
        alias SeqFromTuple = AliasSeq!(
                TL[0].typeOf,
                SeqFromTuple!(Tuple.init.dropOne().typeOf)
        );

}

auto append(T, TT)(TT tuple, T type)
{
    return AliasTuple!(tuple.typeTypeSeq, T)();
}
