///
module rxd.rx.example;

import std.stdio;
import std.traits : Parameters, ReturnType;

enum isObserver(O, E) = is(typeof(useObserver!(O, E)()));

enum isFunctionLike(F, This) =
    is(typeof(F(Parameters!This.init)) : ReturnType!This);

void useObserver(O, E)()
{
    alias OnNext = void delegate(E);
    alias OnComplete = void delegate();
    alias OnError = void delegate(Exception);

    static assert( isFunctionLike!(typeof(&O.init.onNext), OnNext));
    static assert( isFunctionLike!(typeof(&O.init.onComplete), OnComplete));
    static assert( isFunctionLike!(typeof(&O.init.onError), OnError));
}

unittest
{
    class ObserverClass
    {
        void onNext(int) { }
        void onComplete() { }
        void onError(Exception) { }
    }

    struct ObserverStruct
    {
        void onNext(double) const nothrow { }
        void onComplete() @nogc pure { }
        void onError(Exception) @safe const { }
    }

    useObserver!(ObserverClass, int)();
    useObserver!(ObserverStruct, double)();
}

struct Result
{
    alias OnNext = void delegate(int);

    void subscribe(alias onNext)()
    {
        onNext(42);
    }

    void subscribe(O)(O observer)
        if (isObserver!(O, int))
    {
        observer.onNext(42);
    }
}

auto createDummyObservable()
{
    return Result.init;
}

unittest
{

    // defines, but does not invoke, the Subscriber's onNext handler
    // (in this example, the observer is very simple and has only
    // an onNext handler)
    alias myOnNext = (int x) => writeln(x);

    // defines, but does not invoke, the Observable
    auto myObservable = createDummyObservable();

    // subscribes the Subscriber to the Observable, and invokes the Observable
    myObservable.subscribe!(myOnNext)();

    // go on about my business
}
