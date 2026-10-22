------------------------------ MODULE ChainReplication ------------------------------
EXTENDS Naturals, Sequences

CONSTANTS
  Values

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

=============================================================================
