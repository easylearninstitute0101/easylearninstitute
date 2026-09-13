-- Progress 22: Routine / Class Schedule hardening
-- Run after the existing routine/RLS migrations.

create index if not exists idx_routines_institute_teacher_day_time
  on public.routines(institute_id, teacher_id, day_of_week, start_time);
create index if not exists idx_routines_institute_room_day_time
  on public.routines(institute_id, room, day_of_week, start_time)
  where room is not null;

-- Server-side protection against overlapping classes for the same batch,
-- teacher, or room. NULL teacher/room values are intentionally ignored.
create or replace function public.prevent_routine_overlap()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if exists (
    select 1 from public.routines r
    where r.institute_id = new.institute_id
      and r.id <> new.id
      and r.day_of_week = new.day_of_week
      and new.start_time < r.end_time
      and r.start_time < new.end_time
      and (
        r.batch_id = new.batch_id
        or (new.teacher_id is not null and r.teacher_id = new.teacher_id)
        or (new.room is not null and r.room = new.room)
      )
  ) then
    raise exception 'Routine conflict: batch, teacher, or room already has an overlapping class on this day';
  end if;
  return new;
end;
$$;

drop trigger if exists trg_prevent_routine_overlap on public.routines;
create trigger trg_prevent_routine_overlap
before insert or update on public.routines
for each row execute function public.prevent_routine_overlap();
