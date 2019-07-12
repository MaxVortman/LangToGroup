module TM2TM' where

import TMType
import Data.Set (Set)
import qualified Data.Set as Set
import Helpers

disjoinAcceptCommandWithOthers commands accessStates = do
    let isAcceptCommand command access = 
            case (command, access) of 
                ((SingleTapeCommand ((_, _, _), (_, sh, _))) : st, ah : at) -> if sh == ah then isAcceptCommand st at else False
                ([], []) -> True
    let disjoinAcceptCommandWithOthersInternal allCommands acc = 
            case allCommands of
                (h : t) -> if isAcceptCommand h accessStates then (h, acc ++ t) else disjoinAcceptCommandWithOthersInternal t (h : acc)
                [] -> error "No accept command"

    disjoinAcceptCommandWithOthersInternal commands []

-- -- надо *2к команды, дисджойня стейты и обновляя их алфавиты
-- generateSingleMoveCommands commandA commandA1 i oldstates newstates acc =
--     case (i, oldstates, newstates) of
--         (-1, oldstate : t1, newstate : t2) -> 
--             generateSingleMoveCommands commandA commandA1 i t1 t2 (SingleTapeCommand ((emptySymbol, oldstate, rightBoundingLetter), (emptySymbol, newstate, rightBoundingLetter)) : acc)
--         (-1, [], []) -> reverse acc
--         (0, oldstate : t1, newstate : t2) -> 
--             generateSingleMoveCommands commandA commandA1 (i - 1) t1 t2 (SingleTapeCommand ((commandA, oldstate, rightBoundingLetter), (commandA1, newstate, rightBoundingLetter)) : acc)
--         (_, oldstate : t1, newstate : t2) -> 
--             generateSingleMoveCommands commandA commandA1 (i - 1) t1 t2 (SingleTapeCommand ((emptySymbol, oldstate, rightBoundingLetter), (emptySymbol, newstate, rightBoundingLetter)) : acc)

-- getCurrentStates command acc = 
--     case command of
--         SingleTapeCommand ((_, s, _), (_, s1, _)) : t -> getCurrentStates t ((s, s1) : acc)
--         [] -> reverse acc

-- disjoinStates states = do
--     let disjoinStatesInternal states acc =
--             case states of
--                 State h : t ->  disjoinStatesInternal t ((State (getDisjoinLetter h)) : acc)
--                 [] -> reverse acc
--     disjoinStatesInternal states []

-- commandOnetify command = do
--     let (startStates, endStates) = getCurrentStates command []
-- -- как-то так, теперь надо алфавит стейтов засейвить
--     let commandOnetifyInternal oldStates newStates command i acc = 
--             case command of
--                 [SingleTapeCommand ((a, _, _), (a1, _, _))] -> 
--                     (generateSingleMoveCommands a a1 i oldStates endStates []) : acc
--                 SingleTapeCommand ((a, _, _), (a1, _, _)) : t -> 
--                     commandOnetifyInternal newStates (disjoinStates newStates) t (i + 1) ((generateSingleMoveCommands a a1 i oldStates newStates []) : acc)            
--     commandOnetifyInternal startStates (disjoinStates startStates) command -1 []

-- commandsOnetify commands acc =
--     case commands of
--         h : t -> 
--             commandsOnetify t ((commandOnetify h) ++ acc)
--         [] -> acc


startKPlusOneTapeState = State "q_0^{k+1}"
kplus1tapeState = State "q"
firstPhaseFinalStatesTransmition (State [s]) = State ([s] ++ "'")
firstPhaseFinalStatesTransmition (State s) = State (init s ++ "{'" ++ [last s] ++ "}")
finalKPlusOneTapeState = firstPhaseFinalStatesTransmition kplus1tapeState           

firstPhase acceptCommand otherCommands startStates = do

    let generateFirstPhaseCommand command states acc =
            case states of
                [] -> reverse $ (SingleTapeCommand ((emptySymbol, kplus1tapeState, rightBoundingLetter), (Command command, kplus1tapeState, rightBoundingLetter))) : acc
                s : ss  | acc == [] -> generateFirstPhaseCommand command ss $ (SingleTapeCommand ((emptySymbol, s, rightBoundingLetter), (emptySymbol, s, rightBoundingLetter))) : acc 
                        | otherwise -> generateFirstPhaseCommand command ss $ (SingleTapeCommand ((leftBoundingLetter, s, rightBoundingLetter), (leftBoundingLetter, s, rightBoundingLetter))) : acc 
    
    let firstPhaseFinalCommand startStates acc =
            case startStates of
                [] -> reverse $ (SingleTapeCommand ((emptySymbol, kplus1tapeState, rightBoundingLetter), (emptySymbol, finalKPlusOneTapeState, rightBoundingLetter))) : acc
                s : ss  | acc == [] -> firstPhaseFinalCommand ss $ (SingleTapeCommand ((emptySymbol, s, rightBoundingLetter), (emptySymbol, firstPhaseFinalStatesTransmition s, rightBoundingLetter))) : acc 
                        | otherwise -> firstPhaseFinalCommand ss $ (SingleTapeCommand ((leftBoundingLetter, s, rightBoundingLetter), (leftBoundingLetter, firstPhaseFinalStatesTransmition s, rightBoundingLetter))) : acc 
    
    let firstPhaseStartCommand startStates acc =
            case startStates of
                [] -> reverse $ (SingleTapeCommand ((emptySymbol, startKPlusOneTapeState, rightBoundingLetter), (Command acceptCommand, kplus1tapeState, rightBoundingLetter))) : acc
                s : ss  | acc == [] -> firstPhaseStartCommand ss $ (SingleTapeCommand ((emptySymbol, s, rightBoundingLetter), (emptySymbol, s, rightBoundingLetter))) : acc 
                        | otherwise -> firstPhaseStartCommand ss $ (SingleTapeCommand ((leftBoundingLetter, s, rightBoundingLetter), (leftBoundingLetter, s, rightBoundingLetter))) : acc     

    let firstPhaseInternal commands acc = 
            case commands of
                [] -> acc
                h : t -> firstPhaseInternal t $ ((generateFirstPhaseCommand h startStates [])) : acc

    (firstPhaseStartCommand startStates []) : (firstPhaseFinalCommand startStates []) : (firstPhaseInternal otherCommands [])

transformStartStatesInCommands startStates commands = do
    let transformCommand states command acc =
            case (states, command) of
                (h : t, (SingleTapeCommand ((l1, s1, r1), (l2, s2, r2))) : tcommands) 
                    | s1 == h && s2 == h -> transformCommand t tcommands $ (SingleTapeCommand ((l1, firstPhaseFinalStatesTransmition s1, r1), (l2, firstPhaseFinalStatesTransmition s2, r2))) : acc
                    | s1 == h -> transformCommand t tcommands $ (SingleTapeCommand ((l1, firstPhaseFinalStatesTransmition s1, r1), (l2, s2, r2))) : acc
                    | s2 == h -> transformCommand t tcommands $ (SingleTapeCommand ((l1, s1, r1), (l2, firstPhaseFinalStatesTransmition s2, r2))) : acc
                    | otherwise -> transformCommand t tcommands $ (SingleTapeCommand ((l1, s1, r1), (l2, s2, r2))) : acc
                ([], []) -> reverse acc

    let transformStartStatesInCommandsInternal commands acc = 
            case commands of
                h : t -> transformStartStatesInCommandsInternal t $ (transformCommand startStates h []) : acc
                [] -> reverse acc
            
    transformStartStatesInCommandsInternal commands []

generateEmptyStayCommands states acc =
    case states of
        [] -> reverse acc
        h : t -> generateEmptyStayCommands t $ (SingleTapeCommand ((leftBoundingLetter, h, rightBoundingLetter), (leftBoundingLetter, h, rightBoundingLetter))) : acc
        

secondPhase commands startStates accessStates = do
    let transformedCommands = transformStartStatesInCommands startStates commands
    let addKPlusOneTapeCommands c1 c2 acc = 
            case (c1, c2) of
                (h1 : t1, h2 : t2) -> addKPlusOneTapeCommands t1 t2 $ (h1 ++ [SingleTapeCommand ((Command h2, finalKPlusOneTapeState, emptySymbol), (emptySymbol, finalKPlusOneTapeState, Command h2))]) : acc
                ([], []) -> acc

    let returnToRightEndmarkerCommands commands acc = 
            case commands of
                h : t -> returnToRightEndmarkerCommands t $ 
                                ((generateEmptyStayCommands accessStates []) ++ 
                                [SingleTapeCommand ((emptySymbol, finalKPlusOneTapeState, Command h), (Command h, finalKPlusOneTapeState, emptySymbol))]
                                ) : acc
                [] -> acc

    (addKPlusOneTapeCommands transformedCommands commands []) ++ (returnToRightEndmarkerCommands commands [])

thirdPhase commands accessStates = do
    let thirdPhaseInternal commands acc =
            case commands of
                h : t -> thirdPhaseInternal t $ ((generateEmptyStayCommands accessStates []) ++ 
                                                [SingleTapeCommand ((Command h, finalKPlusOneTapeState,  rightBoundingLetter), (emptySymbol, finalKPlusOneTapeState, rightBoundingLetter))]
                                                ) : acc
                [] -> acc
    thirdPhaseInternal commands []

symCommands commands = do
    let reverseCommands commands acc =
            case commands of
                SingleTapeCommand ((a, s, b), (a1, s1, b1)) : t -> reverseCommands t (SingleTapeCommand ((a1, s1, b1), (a, s, b)) : acc)
                [] -> reverse acc

    let reverseAllCommands commands acc =
            case commands of
                h : t -> reverseAllCommands t ((reverseCommands h []) : acc)
                [] -> acc
    reverseAllCommands commands commands

mapTM2TMAfterThirdPhase :: TM -> TM
mapTM2TMAfterThirdPhase 
    (TM
        (inputAlphabet,
        tapeAlphabets, 
        MultiTapeStates multiTapeStates, 
        Commands commands, 
        StartStates startStates, 
        AccessStates accessStates)
    ) = do
        let commandsList = Set.toList commands
        let (acceptCommand, otherCommands) = disjoinAcceptCommandWithOthers commandsList accessStates
        let commandsFirstPhase = firstPhase acceptCommand otherCommands startStates
        let commandsSecondPhase = secondPhase commandsList startStates accessStates
        let commandsThirdPhase = thirdPhase commandsList accessStates

        let newTMCommands = Commands $ Set.fromList $ symCommands $ commandsFirstPhase ++ commandsSecondPhase ++ commandsThirdPhase

        let newTMTapeAlphabets = tapeAlphabets ++ [TapeAlphabet $ Set.map (\c -> Command c) commands]

        let newTMStartStates = StartStates (startStates ++ [startKPlusOneTapeState])

        let newTMMultiTapeStates = MultiTapeStates (
                (zipWith (\set start -> Set.insert (firstPhaseFinalStatesTransmition start) set) multiTapeStates startStates) 
                ++ [Set.fromList [startKPlusOneTapeState, kplus1tapeState, finalKPlusOneTapeState]]
                )

        let newTMAccessStates = AccessStates (accessStates ++ [finalKPlusOneTapeState])

        TM (inputAlphabet, newTMTapeAlphabets, newTMMultiTapeStates, newTMCommands, newTMStartStates, newTMAccessStates)

doubleCommandsStateDisjoinFunction = getDisjoinState    

doubleCommands commands = do
    let divideCommands commands acc =
            case commands of 
                SingleTapeCommand ((a, s, b), (a1, s1, b1)) : t 
                        | b == rightBoundingLetter -> divideCommands t (acc ++ [
                            SingleTapeCommand ((a, s, rightBoundingLetter), (a1, s1, rightBoundingLetter)),
                            SingleTapeCommand ((leftBoundingLetter, doubleCommandsStateDisjoinFunction s, rightBoundingLetter), (leftBoundingLetter, doubleCommandsStateDisjoinFunction s1, rightBoundingLetter))                                                                                                          
                                                                                ]) 
                        | otherwise -> divideCommands t (acc ++ [
                            SingleTapeCommand ((a, s, rightBoundingLetter), (a1, s1, rightBoundingLetter)),
                            SingleTapeCommand ((b, doubleCommandsStateDisjoinFunction s, rightBoundingLetter), (b1, doubleCommandsStateDisjoinFunction s1, rightBoundingLetter))
                                                                 ])
                [] -> acc

    let doubleCommandsInternal commands acc =
            case commands of 
                h : t -> doubleCommandsInternal t ((divideCommands h []) : acc)
                [] -> acc

    doubleCommandsInternal commands []

intermediateStateOne2TwoKTransform (State s) k = State (s ++ (replicate k '\'')) 

one2TwoKCommands commands = do
    let getStartAndFinalStatesOfCommand command (starts, finals) = 
            case command of
                SingleTapeCommand ((l1, s1, r1), (l2, s2, r2)) : t -> getStartAndFinalStatesOfCommand t (s1 : starts, s2 : finals)
                [] -> (reverse starts, reverse finals)
    let oneActionCommand (starts, finals) k command n i (newStarts, acc) =
            case (command, starts, finals) of
                ([], [], []) -> (reverse newStarts, reverse acc)
                (SingleTapeCommand ((l1, s1, r1), (l2, s2, r2)) : t, start : st, final : ft)   
                        | n == i || l1 == emptySymbol -> oneActionCommand (st, ft) k t n (i + 1) (final : newStarts, (SingleTapeCommand ((l1, start, r1), (l2, final, r2))) : acc)
                        | start == final -> oneActionCommand (st, ft) k t n (i + 1) (final : newStarts, (SingleTapeCommand ((emptySymbol, start, r1), (emptySymbol, final, r2))) : acc)
                        | otherwise -> oneActionCommand (st, ft) k t n (i + 1) (intermediateStateOne2TwoKTransform final k : newStarts, (SingleTapeCommand ((emptySymbol, start, r1), (emptySymbol, intermediateStateOne2TwoKTransform final k, r2))) : acc)

    let onew2TwoKCommand (starts, finals) k i command immutCommand acc =
            case command of
                SingleTapeCommand ((l1, s1, r1), (l2, s2, r2)) : t  | l1 == emptySymbol && l2 == emptySymbol || l1 == leftBoundingLetter -> onew2TwoKCommand (starts, finals) k (i + 1) t immutCommand acc
                                                                    | otherwise -> onew2TwoKCommand (newStarts, finals) k (i + 1) t immutCommand $ newCommands ++ acc where (newStarts, newCommands) = oneActionCommand (starts, finals) k immutCommand i 0 ([],[])
                [] -> acc
    let one2TwoKCommandsInternal commands i acc =
            case commands of
                h : t -> one2TwoKCommandsInternal t (i + 1) $ (onew2TwoKCommand (getStartAndFinalStatesOfCommand h ([], [])) i 0 h h []) : acc
                [] -> acc

    one2TwoKCommandsInternal commands 1 []

-- mapTM2TM' :: TM -> TM
-- mapTM2TM' tm = do
--     let (TM (inputAlphabet,
--             tapeAlphabets, 
--             MultiTapeStates multiTapeStates, 
--             Commands commandsSet, 
--             StartStates startStates,
--             AccessStates accessStates)
--             ) = mapTM2TMAfterThirdPhase tm

--     let commands = Set.toList commandsSet
--     let newTMCommands =  doubleCommands commands