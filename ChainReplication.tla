------------------------------ MODULE ChainReplication ------------------------------
EXTENDS Naturals, Sequences

CONSTANTS
  Values,
  MaxInFlight   \* most updates the link can have in flight

VARIABLES 
  headVal,      \* copy of the value at the head node
  tailVal,      \* copy of hte value at the tail node
  link          \* FIFO link between head and tail

vars == <<headVal, tailVal, link>>

InitVal == 0

Reply == [op : {"update", "query"}, val : Values \cup {InitVal}]

TypeOK ==
  /\ headVal \in Values \cup {InitVal}
  /\ tailVal \in Values \cup {InitVal}
  /\ link \in Seq(Values)

Init ==
  /\ headVal = InitVal
  /\ tailVal = InitVal
  /\ link = <<>>

Update(v) ==
  /\ Len(link) < MaxInFlight
  /\ headVal' = v
  /\ link' = Append(link, v)
  /\ UNCHANGED tailVal

Forward ==
  /\ link # <<>>
  /\ tailVal' = Head(link)
  /\ link' = Tail(link)
  /\ UNCHANGED headVal

Next == (\E v \in Values : Update(v)) \/ Forward

Spec ==
  /\ Init /\ [][Next]_vars

=============================================================================
