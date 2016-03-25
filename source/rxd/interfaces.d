module rxd.interfaces;

struct ScheduleToken(Scheduler)
{
    Scheduler.WeakRefOf scheduler;
    size_t idx;

    bool cancel()
    {
        return scheduler && scheduler.cancel();
    }
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
