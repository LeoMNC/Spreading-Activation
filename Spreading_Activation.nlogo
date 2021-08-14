extensions [ nw stats ]
turtles-own [ activation tick_initial_activation to_omit to_leak change side ]
globals [ epsilon bipartite? auto_stop ]


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;BEGINNING OF SETUP COMMANDS;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to setup
  clear-all
  file-close-all

  create_network
  reset_activation
  set epsilon 1e-10

  reset-ticks
end

to create_network ; Pick using the chooser on the Interface Tab

  ; Four styles - Random, Small World, Preferential Attachment, and Bipartite

  ; Random
  if network_style = "Random" [
    nw:generate-random turtles links population p [ fd 15 ]
    layout-radial turtles links turtle 0
  ]

  ; Small World
  if network_style = "Small World" [
    nw:generate-watts-strogatz turtles links population neighborhood_size p [
      fd max-pxcor * .9
    ]
  ]

  ; Preferential Attachment
  if network_style = "Preferential Attachment" [
    nw:generate-preferential-attachment turtles links population neighborhood_size
    layout-radial turtles links turtle 0
  ]

  ; Bipartite
  if network_style = "Bipartite" [
    set bipartite? TRUE ; Keep track of this for the C(x) plot
    create-turtles population [
      set side who mod 2
      ifelse side = 0
      [ setxy random-xcor -10 ]
      [ setxy random-xcor 10 ]
    ]
    ask turtles [
      ask turtles with [ side != [ side ] of myself ] [
        if random-float 1 < p [ create-link-with myself ]
      ]
    ]

    ask turtle 0 [ set xcor 0 ]
  ]

  ; Users can also read in a file using an adjacency matrix
  if network_style = "Read File" [
    nw:load-matrix filename turtles links
    layout-radial turtles links turtle 0
  ]


end

to reset_activation
  ask turtles [ set activation 0 ]
  ask turtle 0 [ set activation 100 ]

  setup_aesthetics
end

to setup_aesthetics
  ask links [ set color black ]
  ask patches [ set pcolor blue ]

  ask turtles [
    set shape "circle"
    set label-color lime
  ]

  adjust_aesthetics
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;END OF SETUP COMMANDS;;;;;;;;;;;;
;;;;;;;;;;;;BEGINNING OF DYNAMICS;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to go
  calculate_amount_to_omit

  spread
  leak

  adjust_aesthetics

  measure_change
  if (converged AND auto_stop = 0) [ stop ]

  tick
end

to calculate_amount_to_omit
  ask turtles [
    set tick_initial_activation activation
    set to_omit (1 - retention) * (activation)
  ]
end

to spread
  ask turtles [
    set activation activation - to_omit
    let amount 0
    if degree self > 0 [ set amount to_omit / degree self ]
    ask link-neighbors [ set activation activation + amount ]
  ]
end

to leak
  ask turtles [ set activation (1 - decay) * activation ]
end


to measure_change
  ask turtles [
    set change abs(tick_initial_activation - activation)
  ]
end

to adjust_aesthetics
  scale_turtle_colors
  update_labels
end

to scale_turtle_colors
  ask turtles [
    set color scale-color red activation 0 max ([activation] of turtles)
  ]
end

to update_labels
  ask turtles [
    ifelse labels?
    [ set label precision activation 2 ]
    [ set label "" ]
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;END OF DYNAMICS;;;;;;;;;;;;;;;
;;;;;;BEGINNING OF REPORTER DEFINITIONS;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to-report total_change
  let activity [ change ] of turtles
  report ( sum activity )
end

to-report converged
  ifelse total_change < epsilon
  [ report TRUE ]
  [ report FALSE ]
end



to-report dispersed
  ifelse any? turtles with [ activation = 0 ]
  [ report FALSE ]
  [ report TRUE ]
end


to-report degree [ turt ]
  report count [ in-link-neighbors ] of turt
end

to-report stand_out [ turt ]
  let act [ activation ] of turt

  let competitors [ in-link-neighbors ] of turt

  let competition 0
  if any? competitors [
    set competition max [ activation ] of competitors
  ]

  report act - competition
end


to-report deg_corr
  ifelse ticks > 0 [
    let data [(list degree self activation)] of turtles
    let tbl stats:newtable-from-row-list data
    let cor-list stats:correlation tbl
    report item 0 item 1 cor-list ] [
    report 0
  ]
end

to-report clust_corr
  ifelse ticks > 0 [
    let data [(list nw:clustering-coefficient activation)] of turtles
    let tbl stats:newtable-from-row-list data
    let cor-list stats:correlation tbl
    report item 0 item 1 cor-list ] [
    report 0
  ]
end

to-report target_act
  report [ activation ] of turtle 0
end

to-report target_so
  report stand_out turtle 0
end

to-report target_deg
  report degree turtle 0
end

to-report target_clust
  report [ nw:clustering-coefficient ] of turtle 0
end

to-report gsize
  report count links
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;END OF COMMANDS;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;ALL CODE WRITTEN BY;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;LEO N-C;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
@#$#@#$#@
GRAPHICS-WINDOW
508
10
1214
717
-1
-1
17.0244
1
12
1
1
1
0
0
0
1
-20
20
-20
20
1
1
1
ticks
30.0

BUTTON
5
169
89
202
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
5
60
185
93
population
population
3
100
20.0
1
1
NIL
HORIZONTAL

CHOOSER
4
11
185
56
network_style
network_style
"Random" "Small World" "Preferential Attachment" "Bipartite" "Read File"
1

SLIDER
5
132
186
165
p
p
0
1
0.2
.01
1
NIL
HORIZONTAL

SLIDER
4
97
186
130
neighborhood_size
neighborhood_size
1
ceiling (population / 2) - 1
2.0
1
1
NIL
HORIZONTAL

BUTTON
5
204
89
237
go
if any? turtles [ go ]
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
91
204
185
237
go once
if any? turtles [ go ]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
91
169
185
202
reset
reset-ticks\nif any? turtles [ reset_activation ]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
4
240
185
273
retention
retention
0
1
0.51
.01
1
NIL
HORIZONTAL

SLIDER
4
278
185
311
decay
decay
0
1
0.0
.01
1
NIL
HORIZONTAL

PLOT
5
503
499
718
Activation Value Predictors
time
correlation
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"degree" 1.0 0 -10649926 true "" "plot deg_corr"
"c(x)" 1.0 0 -2674135 true "" "if bipartite? != TRUE [plot clust_corr]"
"null (0)" 1.0 0 -16777216 true "" "plot 0"

PLOT
206
157
499
310
Total Change over Time
time
NIL
0.0
20.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot total_change"

INPUTBOX
205
12
299
72
filename
matrix.txt
1
0
String

BUTTON
205
75
299
117
Save Network
nw:set-context turtles links\nnw:save-matrix filename
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
4
315
499
498
Activation Distribution
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "histogram [activation] of turtles"

MONITOR
323
59
498
104
Total Change Since Last Tick
total_change
10
1
11

MONITOR
323
10
498
55
All Nodes Are Active
dispersed
17
1
11

MONITOR
323
107
498
152
Max Change Since Last Tick
max [ change ] of turtles
17
1
11

SWITCH
205
121
300
154
labels?
labels?
0
1
-1000

@#$#@#$#@
## WHAT IS IT?

The model implements of a spreading-activation algorithm over networks of varying topologies. In particular, it displays the evolution of the correlation between activation and two micro-level network properties, degree and clustering coefficient. This spreading-activation algorithm has been used in prior psycholinguistic research to explain human behavior on a wide variety of tasks involving speech perception and production. 

However, this prior research has focused primarily on predictive models, focusing on the dispersion at the conclusion of a pre-selected number of time-steps. Our present goal is to explain and describe the interaction between the network's topology and the spreading-activation algorithm, rather than measure the algorithm's performance on specific complex networks and compare its output to human behavior. The NetLogo implementation, and the broader paradigm of agent-based modeling, puts front and center the system's state-space and its dynamics.

## HOW IT WORKS

There are only two kinds of agents, those used in classic network studies - nodes and links. At setup, one node (the "target node") receives 100 points of activation and each other node receives 0. "Random" networks are implemented by the Gilbert model (1959). "Small World" networks are implemented by the Watts-Strogatz model (1998). "Preferential Attachment" networks are implemented by the Barabasi-Albert model (1999). Users may also load in their own networks using files containing the adjacency matrix.

Each tick, the system begins by calculating the amount of activation each node will emit that tick. Once that calculation is completed, nodes then split that amount evenly among their neighbors. If the node has no neighbors, the activation disappears from the system. Finally, each node decays in activation. For details, see Vitevitch, Ercal, & Adagarla (2011) and Siew (2019).

The model converges when the sum change in activation over the course of a tick is less than 1e-10, defined as "epsilon" in the code.

## HOW TO USE IT

Users can use the 'filename' input to interact with the "Read Network" setup option and the "Save Network" button. When using this option, all parameters are ignored; the network is simply a faithful copy of the adjacency matrix stored in the file. See the "Reading and Writing Files" section for more information.

The population slider determines the number of nodes in the network. 

The neighborhood-size slider is inert in the random network. In the small-world network, it describes the number of nodes (in each direction) that each node will be neighbors with, prior to rewiring. In the preferential attachment network, it determines the number of nodes that each node will attach to when introduced to the network. 

In the random network, the p slider determines the probability that any given pair of nodes is connected by a link. In the small-world network, it determines the probability that any given link is rewired. In the preferential attachment network, it is inert.

The retention slider determines the amount of activation each node retains on each tick. For example, on the first tick, the target node multiplies its 100 points of activation by the retention parameter. It then divides the remaining points equally among its neighbors.

The decay parameter determines the amount of activation the system will leak over time. Each tick, after all spreading actions occur, each node multiplies sets its activation value to its current activation value multiplied by (1 - decay).

The first plot measures the total change in the the distribution of activation over time. Each node measures its change with abs(activation at beginning of tick - activation at end of tick). The total change is the sum of the change measured by each node. When total change = 0, the model converges.

The second plot measures the correlation of activation and two micro-level network metrics - degree and C(x). By convergence, activation and degree are perfectly correlated, with high-degree nodes holding more activation than low-degree nodes.

## READING AND WRITING FILES

The model allows users to read networks from adjacency matrices using the nw:load-matrix command. The corresponding adjacency matrix must be in the same folder as the NetLogo model is saved in, unless the user has set a different working directory using the Command Center. To load the file, the user must enter its name into the Input object in the Interface titled 'filename'. The extension (.txt) must be included.

The model also allows the user to save generated networks using nw:save-matrix. The file will be created in the same folder as the NetLogo model, or in the working directory if this has been changed by the user. This allows the user to perform multiple runs on the same networks, even using BehaviorSpace.

For technical notes, see [the documentation for the nw extension](https://ccl.northwestern.edu/netlogo/docs/nw.html).

## THINGS TO NOTICE

First, note that the underlying spreading-activation algorithm is deterministic. This means that, holding the spreading-activation parameters constant, all between-run variance is driven entirely by the process of network generation.

The most notable finding is that, for any given (connected) topology, there is a single attractor state whose basin of attraction is the entire state-space of the system. In that state, each node's activation value is fully described by a positive linear function of that node's degree. This entails that the distribution of activation is perfectly described by the network's degree distribution. In other words, both C(x) and the network's higher-level topological properties have no impact on the convergence point.

Moreover, the system smoothly approaches this point without fluctuations, with rare exceptions when retention is especially low. The system's convergence is visualized in the Activation Values Predictors chart, where the attractor state is represented by a correlation of 1 between activation value and degree. Convergence is especially quick in dense networks, and the steady path toward it is the main driver of system dynamics at every point. This is in conflict with prior research, which has claimed that, in substantial sections of the state-space, high values for both degree and C(x) have robust negative causal impacts on the node's activation value. 

Note that this description of the state-space is conditional on the decay parameter being set to 0, as is typical in this research. That will be a running assumption in our discussion here. Note also that this attractor state can be fully described without referencing the retention value, and is therefore independent of it. Because the basin of attraction is the entire state-space, the convergence point is also independent of the initial distribution of activation. 

Further, note that there is a significant variation in the between-run effects of C(x). This is true even holding the network-construction method constant. This implies that the direction and strength of the effect of C(x) depends on the network's particulars, and cannot be reduced to facts about the construction method. For example, holding p constant, different random networks will have different trajectories for the effect of C(x). This is because different networks will have different correlations between C(x) and degree, which serves as a confound.

Finally, note that when using bipartite networks, each node necessarily has C(x) = 0. Thus, the C(x) predictor is not plotted.

## THINGS TO TRY

The effect of network structure on resting-state activation values is most clear when the population is divisible by ten. This is simply because the initial state arbitrarily assigns 100 units of activation to one node. These 100 units evenly divide up on regular networks, such as a ring or complete network. 

Create a complete network using the random model with p = 1; create a ring using the small-world model with p = 0. Varying the topology slightly, by setting offsetting p from 0 (on a ring) or 1 (on the complete network), and observe its effects on the dynamics and end-point.

Play around with the "labels?" switch and choose a preferred visualization. It is recommended that labels be present when the population is low, and absent when the population is high.

Load in complex networks of your choice (see nw:load-matrix for usage). Note that the target node will always be node 0, represented by the first line of the adjacency matrix.

Save networks generated here, then load them in to examine the same network under many parameters.

## EXTENDING THE MODEL

The primary function of this implementation of the spreading-activation algorithm is not to develop a novel model, but rather to use the agent-based modeling framework to more closely examine claims that have been made using other implementations. Thus, extending the present model is not especially fruitful. Rather, we should analyze whether the dynamics of the current model can explain human behavior. If not, what is needed is a novel model of the task in question, not an extension of the present model.

There are some small extensions of the model that do not change the fundamental assumptions. For example, new topologies could be used to further explore how network structure interacts with spreading activation. These new topologies could include features common in the Network Science literature but not implemented presently, including links that are one-directional and/or weighted. 

Additionally, the model could be extended so that the user has more control over the initial distribution of activation. While the interface does not presently support users performing custom initial distributions, this can be done using the Command Center. For example, the following code would "reset" the activation values, with the new initalization splitting the activation between two nodes:

ask turtles [ set activation 0 ]
ask turtle 0 [ set activation 20 ]
ask turtle 1 [ set activation 80 ]

## NETLOGO FEATURES

The model uses the nw extension to create, read, and write networks, and it uses the stats extension to measure correlations.

## RELATED LITERATURE

This model furthers research on spreading-activation first put forward in the domain of Cognitive Network Science. This NetLogo model implements a traditional spreading-activation algorith described first in Vitevitch, Ercal, & Adagarla (2011) and implemented in the R package {spreadr} (Siew, 2019). This previous research appeals to this spreading-activation algorithm to explain the effects of network-level metrics in human behavior. Specifically, it has been argued that the structure of lexical similarity networks, which are constructed using the edit distance metric (Vitevitch, 2008; Arbesman, Strogatz, & Vitevitch, 2010), can affect speech perception and generation through both various network-level properties, and that the spreading-activation mechanism can explain several of these effects. For a review, see Vitevitch (2021).

It is a well-known fact that speech perception is facilitated when the stimulus word is relatively distinct from other words (Pisoni & Luce, 1998; Vitevitch, Stamer, & Sereno, 2008). For example, a word like "back," which has many similar-sounding words, is likely to be harder to perceive than a word such as "bag," which has relatively few similar-sounding words. This is traditionally interpreted as evidence that mental representations of lexical items compete with one another during spoken word recognition, possibly via inhibitory links. In terms of lexical similarity networks, this means that having a high degree impedes processing. 

Further, Chan & Vitevitch (2009) found that words with a low clustering coefficient, or C(x), were more easily recognized, even when controlling for degree and other relevant psycholinguistic variables. They proposed a verbal model whereby words with low C(x), relative to words with high C(x), stood out more prominently relative to competing neighbor nodes due to the quick diffusion of activation beyond the local neighborhood. Chan & Vitevitch (2010) found a parallel effect on speech production.

Vitevitch, Ercal, & Adagarla (2011) argued that a spreading-activation algorithm explained these effects. They did so by isolating the two-hop neighborhood of the nodes representing the stimuli in the experiments of Chan & Vitevitch (2008) and simulating spreading-activation using those nodes as the target nodes. These findings are contested by simple observations using the present implementation of the spreading-activation mechanism.

Siew (2019) implemented the same spreading-activation algorithm in an R package titled spreadr. This NetLogo model allows the user to more closely examine what's going on under the hood of these algorithms.

## RELATED MODELS

### Network Related
Giant Component
Preferential Attachment
Small Worlds

### Diffusion Related
Virus on a Network
Diffusion on a Directed Network

## CREDITS AND REFERENCES

Arbesman, S., Strogatz, S. H., & Vitevitch, M. S. (2010). The structure of phonological networks across multiple languages. International Journal of Bifurcation and Chaos, 20(03), 679-685.

Barabási, A. L., & Albert, R. (1999). Emergence of scaling in random networks. Science, 286(5439), 509-512.

Chan, K. Y., & Vitevitch, M. S. (2009). The influence of the phonological neighborhood clustering coefficient on spoken word recognition. Journal of Experimental Psychology: Human Perception and Performance, 35(6), 1934.

Chan, K. Y., & Vitevitch, M. S. (2010). Network structure influences speech production. Cognitive Science, 34(4), 685-697.

Gilbert, E. N. (1959). Random graphs. The Annals of Mathematical Statistics, 30(4), 1141-1144.

Luce, P. A., & Pisoni, D. B. (1998). Recognizing spoken words: The neighborhood activation model. Ear and Hearing, 19(1), 1.

Siew, C. S. (2019). spreadr: An R package to simulate spreading activation in a network. Behavior Research Methods, 51(2), 910-929.

Vitevitch M. S. (2008). What can graph theory tell us about word learning and lexical retrieval?. Journal of speech, language, and hearing research : JSLHR, 51(2), 408–422.

Vitevitch, M. S., Ercal, G., & Adagarla, B. (2011). Simulating retrieval from a highly clustered network: Implications for spoken word recognition. Frontiers in psychology, 2, 369.

Vitevitch, M. S., Stamer, M. K., & Sereno, J. A. (2008). Word length and lexical competition: Longer is the same as shorter. Language and Speech, 51(4), 361-383.

Watts, D. J., & Strogatz, S. H. (1998). Collective dynamics of ‘small-world’networks. Nature, 393(6684), 440-442.

All correspondence related to this model should be written to LeoNiehorsterCook@gmail.com.
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.2.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="compare" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="10000"/>
    <metric>target_act</metric>
    <enumeratedValueSet variable="population">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network_style">
      <value value="&quot;Small World&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="neighborhood_size">
      <value value="2"/>
      <value value="3"/>
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="p">
      <value value="0"/>
    </enumeratedValueSet>
    <steppedValueSet variable="retention" first="0" step="0.1" last="0.9"/>
    <enumeratedValueSet variable="decay">
      <value value="0"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment1" repetitions="10000" runMetricsEveryStep="true">
    <setup>setup
set auto_stop FALSE</setup>
    <go>go</go>
    <exitCondition>converged AND ticks &gt; 200</exitCondition>
    <metric>dispersed</metric>
    <metric>target_deg</metric>
    <metric>target_clust</metric>
    <metric>target_act</metric>
    <metric>target_so</metric>
    <metric>deg_corr</metric>
    <metric>clust_corr</metric>
    <metric>gsize</metric>
    <metric>total_change</metric>
    <enumeratedValueSet variable="neighborhood_size">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="filename">
      <value value="&quot;matrix.txt&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="decay">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network_style">
      <value value="&quot;Random&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="population">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="p">
      <value value="0.1"/>
    </enumeratedValueSet>
    <steppedValueSet variable="retention" first="0" step="0.1" last="0.9"/>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
