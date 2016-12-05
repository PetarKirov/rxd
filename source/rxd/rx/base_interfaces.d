module rxd.rx.base_interfaces;

///
interface IDisposable
{
    ///
    bool dispose();
}

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
unittest
{
    class ObservableNumber : IObservable!int
    {
        private int number;
        private IObserver!int[] observers;

        private void publish()
        {
            foreach (o; observers)
                o.onNext(this.number);
        }

        int opUnary(string op)()
        {
            this.number = mixin (op ~ "this.number");
            publish();
            return this.number;
        }

        int opBinary(string op, T)(T other) const
            if (is(T : int))
        {
            return mixin ("this.number" ~ op ~ "other");
        }

        int opAssign(T)(T other) if (is(T : int))
        {
            this.number = other;
            publish();
            return this.number;
        }

        int opOpAssign(string op, T)(T other) if (is(T : int))
        {
            mixin ("this = this " ~ op ~ " other;");
            return this.number;
        }

        class Ticket : IDisposable
        {
            this(size_t idx) { this.idx = idx; }
            private const size_t idx;
            bool dispose()
            {
                if (this.outer.observers[idx] !is null)
                {
                    this.outer.observers[idx] = null;
                    return true;
                }
                else
                    return false;
            }
        }

        IDisposable subscribe(IObserver!int o)
        {
            observers ~= o;
            o.onNext(this.number);
            return new Ticket(observers.length - 1);
        }
    }

    class NumberObserver : IObserver!int
    {
        int[] result;
        void onNext(int x) { result ~= x; }
        void onError(Exception error) { assert (0); }
        void onCompleted() { assert (0); }
    }

    auto observervable = new ObservableNumber;
    auto observer = new NumberObserver;

    auto ticket = observervable.subscribe(observer);
    assert ((cast(ObservableNumber.Ticket)ticket).idx == 0);
    assert (observervable.observers.length == 1);
    assert (observer.result == [ 0 ]);

    observervable++;
    observervable += 3;
    observervable *= 2;

    assert (observervable.number == 8);
    assert (observer.result == [ 0, 1, 4, 8 ]);
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
