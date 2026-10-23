------------------------------ MODULE ChainReplication ------------------------------
EXTENDS Naturals, Sequences

CONSTANTS
  Values,
  MaxUpdates,   \* most updates the link can have in flight
  MaxQueries    \* most queries the link can have in flight

VARIABLES 
  headVal,      \* copy of the value at the head node
  tailVal,      \* copy of hte value at the tail node
  link,         \* FIFO link between head and tail
  replies       \* every reply tail has sent

vars == <<headVal, tailVal, link, replies>>

InitVal == 0

Reply == [op : {"update", "query"}, val : Values \cup {InitVal}]

IsUpdate(r) == r.op = "update"
IsQuery(r) == r.op = "query"

Acked == Len(SelectSeq(replies, IsUpdate))
QueryCount == Len(SelectSeq(replies, IsQuery))

TypeOK ==
  /\ headVal \in Values \cup {InitVal}
  /\ tailVal \in Values \cup {InitVal}
  /\ link \in Seq(Values)
  /\ replies \in Seq(Reply)

Init ==
  /\ headVal = InitVal
  /\ tailVal = InitVal
  /\ link = <<>>
  /\ replies = <<>>

Update(v) ==
  /\ Acked + Len(link) < MaxUpdates
  /\ headVal' = v
  /\ link' = Append(link, v)
  /\ UNCHANGED <<tailVal, replies>>

Forward ==
  /\ link # <<>>
  /\ tailVal' = Head(link)
  /\ link' = Tail(link)
  /\ replies' = Append(replies, [op |-> "update", val |-> Head(link)])
  /\ UNCHANGED headVal

Query ==
  /\ QueryCount < MaxQueries
  /\ replies' = Append(replies, [op |-> "query", val |-> tailVal])
  /\ UNCHANGED <<headVal, tailVal, link>>

Next == (\E v \in Values : Update(v)) \/ Forward \/ Query

Spec ==
  /\ Init /\ [][Next]_vars

\* collect all update replies sent before reply r
UpdatesBefore(r) == SelectSeq(SubSeq(replies, 1, r - 1), IsUpdate)

\* the value from the last reply in s or 0 if nothing was sent yet
LastVal(s) == IF s = <<>> THEN InitVal ELSE s[Len(s)].val

\* what value was written by hte last acked update u
LastAckedBefore(u) == LastVal(UpdatesBefore(u))

\* for every reply r, if it was to a query request, its value is the last one acked at the time it was sent
StrongConsistency ==
  \A r \in 1..Len(replies) :
    IsQuery(replies[r]) => replies[r].val = LastAckedBefore(r)

=============================================================================
