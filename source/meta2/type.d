///
module rxd.meta2.type;

import std.traits : isInstanceOf;

///
enum isType(T) = isInstanceOf!(Type, T);

///
enum isAliasTuple(T) = isInstanceOf!(AliasTuple, T);

///
auto type(T)()
{
    return Type!T.init;
}

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
struct Type(T)
{
    alias type = T;

    bool opEquals(U)(Type!U other)
    { return is(T == U); }

    auto opSlice()()
    { return Type!(T[]).init; }

    auto opIndex(K)(K keyType) if (isType!K)
    { return Type!(T[keyType.type]).init; }

    auto constOf()()
    { return Type!(const(T)).init; }

    auto immutableOf()()
    { return Type!(immutable(T)).init; }

    auto sharedOf()()
    { return Type!(shared(T)).init; }

    string toString()
    {
        return "Type!("~T.stringof~")";
    }
}

unittest
{
    Type!int t;

    auto t2 = t.constOf;

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
                TL[0].type,
                SeqFromTuple!(Tuple.init.dropOne().typeOf)
        );

}

auto append(T, TT)(TT tuple, T type)
{
    //pragma (msg, "append:", TT, T);
    return AliasTuple!(tuple.typeTypeSeq, T)();
}


