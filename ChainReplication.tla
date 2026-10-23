------------------------------ MODULE ChainReplication ------------------------------
EXTENDS Naturals, Sequences

CONSTANTS
  Values,
  MaxUpdates,   \* total updates clients can make
  MaxQueries    \* total queries clients can make

VARIABLES 
  headVal,      \* copy of the value at the head node
  tailVal,      \* copy of hte value at the tail node
  link,         \* FIFO link between head and tail
  replies,      \* every reply tail has sent
  updates       \* every update head has applied

vars == <<headVal, tailVal, link, replies, updates>>

InitVal == 0

Reply == [op : {"update", "query"}, val : Values \cup {InitVal}]

IsUpdate(r) == r.op = "update"
IsQuery(r) == r.op = "query"

Acked == Len(SelectSeq(replies, IsUpdate))
QueryCount == Len(SelectSeq(replies, IsQuery))

\* the value of the storage variable after the first k updates
ValueAfter(k) == IF k = 0 THEN InitVal ELSE updates[k]

\* collect all update replies sent before reply r
UpdateRepliesBefore(r) == SelectSeq(SubSeq(replies, 1, r - 1), IsUpdate)

\* the value from the last reply in s or 0 if nothing was sent yet
LastVal(s) == IF s = <<>> THEN InitVal ELSE s[Len(s)].val

\* the value of the last update that was acked before reply r
LastAckedBefore(r) == LastVal(UpdateRepliesBefore(r))

TypeOK ==
  /\ headVal \in Values \cup {InitVal}
  /\ tailVal \in Values \cup {InitVal}
  /\ link \in Seq(Values)
  /\ replies \in Seq(Reply)
  /\ updates \in Seq(Values)

Init ==
  /\ headVal = InitVal
  /\ tailVal = InitVal
  /\ link = <<>>
  /\ replies = <<>>
  /\ updates = <<>>

Update(v) ==
  /\ Len(updates) < MaxUpdates
  /\ headVal' = v
  /\ link' = Append(link, v)
  /\ updates' = Append(updates, v)
  /\ UNCHANGED <<tailVal, replies>>

Forward ==
  /\ link # <<>>
  /\ tailVal' = Head(link)
  /\ link' = Tail(link)
  /\ replies' = Append(replies, [op |-> "update", val |-> Head(link)])
  /\ UNCHANGED <<headVal, updates>>

Query ==
  /\ QueryCount < MaxQueries
  /\ replies' = Append(replies, [op |-> "query", val |-> tailVal])
  /\ UNCHANGED <<headVal, tailVal, link, updates>>

Next == (\E v \in Values : Update(v)) \/ Forward \/ Query

Spec ==
  /\ Init /\ [][Next]_vars

\* reads at head instead
BadQuery ==
  /\ QueryCount < MaxQueries
  /\ replies' = Append(replies, [op |-> "query", val |-> headVal])
  /\ UNCHANGED <<headVal, tailVal, link, updates>>

BadNext == (\E v \in Values : Update(v)) \/ Forward \/ BadQuery

BadSpec == Init /\ [][BadNext]_vars

\* for every reply r, if it was to a query request, its value is the last one acked at the time it was sent
StrongConsistency ==
  \A r \in 1..Len(replies) :
    IsQuery(replies[r]) => replies[r].val = LastAckedBefore(r)

HeadIsLatest == headVal = ValueAfter(Len(updates))

TailIsAcked == tailVal = ValueAfter(Acked)

\* the link has the un-acked updates
LinkHasPending ==
  /\ Acked + Len(link) = Len(updates)
  /\ link = SubSeq(updates, Acked + 1, Len(updates))

=============================================================================
