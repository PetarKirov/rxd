///
module rxd.rx.scheduling_interfaces;

import rxd.meta2.traits;

///
struct ScheduleToken(Scheduler)
    if (isFuncLike!(typeof(Scheduler.cancel), bool function(size_t)))
{
    Scheduler.WeakRefOf scheduler;
    size_t idx;

    ///
    bool cancel()
    {
        return scheduler && scheduler.cancel(idx);
    }
}

///
interface IScheduler
{
    import core.time : MonoTime;

    alias WeakRefOf = typeof(this);
    alias Token = ScheduleToken!IScheduler;
    alias CallbackFn(Input) = ScheduleToken function(IScheduler, Input);
    alias CallbackDg(Input) = ScheduleToken delegate(IScheduler, Input);

    ///
    MonoTime now();

    ///
    Token schedule(Input)(Input input, Duration timeout, CallbackFn!S action);

    ///
    Token schedule(Input)(Input input, Duration timeout, CallbackDg!S action);

    ///
    bool cancel(size_t idx);
}
