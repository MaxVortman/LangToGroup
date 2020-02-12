module DotGraphWriter where

import SMPrinter
import SMType
import System.IO
import Prelude hiding (Word)
import Text.LaTeX.Base.Render
import Text.LaTeX.Base
import Text.LaTeX.Base.Class
import Text.LaTeX.Packages.Inputenc
import Lib
import Data.Map (Map)
import qualified Data.Map as Map
import Data.Maybe

tex2text tex = show $ render $ execLaTeXM tex

writeGraph :: ([(Word, Int, Word)], Map Word Int) -> Handle -> IO ()
writeGraph graph_map handle =
            do  hPutStr handle "digraph graphname {\n"
                mapM_ ( \x -> 
                            hPutStr handle ((fromJust $ Map.lookup x str_m) ++ " [label=" ++
                            (tex2text $ doLaTeX x) ++
                            "];\n")) a
                mapM_ ( \(from, rule_i, to) -> 
                                hPutStr handle (
                                (fromJust $ Map.lookup from str_m) ++ 
                                " -> " ++
                                (fromJust $ Map.lookup to str_m) ++ 
                                "[label=\"" ++
                                (show rule_i) ++
                                "\"];\n")) graph
                hPutStr handle "}\n"
                hFlush handle
                        where 
                                (graph, m) = graph_map
                                a = map fst $ Map.toList m
                                str_m = Map.fromList $ zip a $ map ((++) "a" . show) [1..]