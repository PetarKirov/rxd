/// This module defines the core transducer primitives.
module rxd.xf.xform;

import std.meta, std.traits;
import std.range : ElementType;

import rxd.meta2.lambda : λ;
import rxd.meta2.switch_n : switch2, switch3;

auto outputRf = λ!((output, input)
{
    import std.range : put;
    output.put(input);
    return output;
});

auto transform(alias fn, I, O)(I input, O output)
{
    return input.accumulate(map!fn()(outputRf), output);
}

private T[n] s(T, size_t n)(T[n] literal) { return literal; }

/// Showcase transform (map + copy)
nothrow @safe @nogc
unittest
{
    auto arr1 = [4, 2, 7, 4, 6, 5, 1].s;
    auto arr2 = typeof(arr1).init;

    transform!(x => x * 2)(arr1[], arr2[]);

    assert (arr2 == [8, 4, 14, 8, 12, 10, 2]);
}

/// Showcase type sequence transformation
pure nothrow @safe @nogc
unittest
{
    import rxd.meta2.type;
    import std.meta : AliasSeq;

    auto trf = λ!( (state, input) => state.append(input) );

    alias transform = (input, xform) =>
        accumulate(input, xform(trf), aliasTuple());

    auto tuple = AliasTuple!(Type!int, Type!double, Type!char)();

    auto large = filter!(t => t.type.sizeof >= 4);
    auto result1 = transform(tuple, large);
    static assert (is(result1.typeSeq == AliasSeq!(int, double)));

    auto toArray = map!(t => t[]);
    auto result2 = transform(tuple, toArray);
    static assert (is(result2.typeSeq == AliasSeq!(int[], double[], char[])));

    auto xf = large(toArray(trf));
    auto result3 = tuple.accumulate(xf, aliasTuple());
    static assert (is(result3.typeSeq == AliasSeq!(int[], double[])));
}

/// Showcase reduce-like usage
pure nothrow @safe @nogc
unittest
{
    import std.range : iota, chain;

    assert (1.iota(4).accumulate(λ!((a, b) => a + b), 0) == 6);

    assert (1.iota(5).accumulate(λ!((a, b) => a * b), 1) == 24);

    //assert (["I", "am", "one"].s[].accumulate(λ!((a, b) => chain(a, b, " ")), "") == "I am one ");
}

/// Showcase composition
unittest
{
    import std.stdio, std.range;
    auto sum = λ!((a, b) => a + b);

    auto odd = filter!(x => x % 2 == 1);
    assert (1.iota(4).accumulate(odd(sum), 0) == 1 + 3);

    auto mulBy2 = map!(x => x * 2);
    assert (1.iota(4).accumulate(mulBy2(sum), 0) == 2 + 4 + 6);

    assert (1.iota(4).accumulate(odd(mulBy2(sum)), 0) == 2 + 6);
}

///
unittest
{
    //auto rangeWrapperRf = λ!((state, input)
    //{
    //    import std.range : put;
    //    output.put(input);
    //    return output;
    //});

    //alias sequence = (input, xform) =>
    //    input.accumulate(xform(outputRf), output);

    //writeln(transform([1, 2, 3], map2((int x) => x + 1)));
}

///
auto map(alias mapFn)()
{
    return λ!((step) {
        return λ!((result, input) {
            return step(result, mapFn(input));
        });
    });
}

///
auto filter(alias filterPred)()
{
    return λ!(
        (step)
        {
            return λ!(
                (rf, result, input)
                {
                    import rxd.meta2.type : isType, isAliasTuple;
                    static if (isType!(typeof(input)) ||
                            isAliasTuple!(typeof(input)))
                    {
                        static if (filterPred(typeof(input).init))
                            return rf(result, input);
                        else
                            return result;
                    }
                    else
                    {
                        return filterPred(input)?
                            rf(result, input) :
                            result;
                    }

                    //mixin (switch2!(
                    //    "filterPred(input)",
                    //    "return rf(result, input);",
                    //    "return result;",
                    //));
                }
            )(step);
        }
    );
};

///
auto accumulate(Rf, S, In, size_t line = __LINE__)(In input, Rf step, S state)
    if ( is(ElementType!In E))
{
    pragma (msg, line.stringof ~ " accumulate: S(", typeof(S.init),
            "), E(", typeof(ElementType!In.init), ") ");

    static if (__traits(compiles, { enum b = input.empty; } ))
    {
        static if (input.empty)
            return state;
        else
            return step(accumulate(input.dropBackOne, step, state), input.back);
    }
    else
    {
        foreach (elem; input)
                state = step(state, elem);

            return state;
    }
//    mixin (switch3!("input.empty",
//        "return state;",
//        "return step(accumulate(input.dropBackOne, step, state), input.back);",
//        q{
//            foreach (elem; input)
//                state = step(state, elem);
//
//            return state;
//        }
//    ));
}

///



struct Transducer(Input, Output = Input)
{

}

unittest
{
    //Transducer!int filter_odd = filter((int x) => x % 2);

    //Transducer!(int, string) serialize = map((int x) => "int" );
}
