module rxd.base_interfaces;

///
interface IObserver(T)
{
    ///
    void onNext(T value);

    ///
    void onError(Exception error);

    ///
    void onCompleted();
}

///
unittest
{
    int n, e, c;
    class NumberObserver : IObserver!int
    {
        import std.stdio;
        void onNext(int x) { n += x; }
        void onError(Exception err) { e++; }
        void onCompleted() { c++; }
    }

    auto o = new NumberObserver();

    foreach (i; 0 .. 5)
        o.onNext(i);

    o.onCompleted();

    assert (n == 10);
    assert (e == 0);
    assert (c == 1);
}

///
interface IObserver(T, Result)
{
    ///
    Result onNext(T value);

    ///
    Result onError(Exception error);

    ///
    Result onCompleted();
}

///
interface IObservable(T)
{
    IDisposable subscribe(IObserver!T observer);
}

///
interface ISubject(I, O) : IObserver!I, IObservable!O
{
}

///
interface ISubject(T) : ISubject!(T, T)
{
}

///
interface IConnectableObservable(T) : IObservable!T
{
    IDisposable connect();
}

interface IEventPattern(Sender, EventArgs)
{
    Sender sender();
    EventArgs eventArgs();
}
