library(dplyr)
library(ggplot2)
cards <- factor(c(1:13), labels = c("2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K", "A"))
suits <- factor(c(1:4), labels = c("♠", "♥", "♧", "♦"))
deck <- data.frame(expand.grid(cards, suits))
colnames(deck) <- c("card", "suit")

str(deck)

nplayers <- 6
ndecks <- 1

deal <- function(ndecks=2, nplayers=2, ncards=2, seed=123){
  # returns a list
  # - your cards
  # - unused  cards
  # - list of your oponents and their cards
  # - flop
  # - turn
  # - river
  full_deck <- deck %>% slice(rep(row_number(), ndecks)) %>% as.data.frame()
  set.seed(seed)
  # shuffle
  ndealt <- ncards * nplayers
  nremaining <- ndecks * nrow(deck) - ndealt
  shuffled_index <- sample(c(1:nrow(full_deck)), size=nrow(full_deck), replace=F)
  dealtindexes <- shuffled_index[1: ndealt]
  deckindexes <- shuffled_index[(ndealt + 1):length(shuffled_index)]
  me <- full_deck[dealtindexes[1:2], ]
  players = list()
  for( i in c(1: (nplayers))){
    j = i - 1
    players[[i]] = full_deck[dealtindexes[(1+(2*j)):(2+(2*j))],]
  }
  flop = deckindexes[1:3]
  turn = deckindexes[4]
  river = deckindexes[5]
  unused = c(deckindexes[6:length(deckindexes)])
  if (nrow(full_deck) != sum(length(flop), length(river), length(turn), length(dealtindexes), length(unused))) warning("you done messed up")
  return(list(me=me, remaining=full_deck[unused, ], players=players, flop=full_deck[flop, ], turn=full_deck[turn, ], river=full_deck[river, ]))  

}


#####################################  methods
is_sequential <- function(x){
  all(abs(diff(as.numeric(x))) == 1)
}  
flush <- function(mycards){
  return(suits[table(mycards$suit) == 5][1])
  # for (i in c(1:length(suits))){
  #   if (nrow(shown[shown$suit == suits[i], ]) > 4){
  #     return(suits[i])
  #   }
  # }
  # return(NA)
}
straight <- function(mycards){
  sorted_cards <- sort(mycards$card)
  if (length(sorted_cards) < 5){
    return(NA)
  }
  # get all the 5 card combinations after sorting
  for (i in c(0: (length(sorted_cards) %% 5))){
    subset = sorted_cards[(i + 1): (i + 5)]
    if (is_sequential(subset))
      return(subset)
  }
  return(NA)
}

###
current_prob_of_pair <- function(mycards){
  nhere <- nrow(mycards)
  nleft <- 52 - nhere
  to_draw = 7 - nhere
  # do we have a pair?
  if (any(table(mycards$card) == 2)){
    return (1)
  # do we have draws left?
  } else if (to_draw == 0){
    return (0)
  } else{
    # for each of the remaining draws, get the probability of not finding a pair
    "say there are 2 left.  5 cards are out (flop + hand), so there are 47 cards left in the deck.
    There are 5 cards that we could get a pair with (though we really want one in our hand)
    So, the number of cards that wont pair is the (number left in the deck) - (number of cards we could pair).  
    We divide that by the number of cards left in the deck.
    For each subsequent draw, adjust the card numbers, and multiply that "
    p = 0
    for(i in c(0: (to_draw - 1))){
      # print(i)
      this_prob = 1 - (((nleft - i) - (nhere +i))/(nleft - i))
      # print(this_prob)
        p = p + this_prob
    }
    #print(p)
    return(p)
    # return(
    #   1 - (
    #     ((choose(nhere, )^to_draw) * choose(13, to_draw))/
    #       choose(52, to_draw)
    #   )
    # )
  }
}
current_prob_of_two_pair <- function(mycards){
  nhere <- nrow(mycards)
  nleft <- 52 - nhere
  to_draw = 7 - nhere
  if (sum(table(mycards$card) == 2) >=2 ){
    return (1)
    # do we have draws left?  and do we have at least one pair?
  } else if (to_draw == 0 | sum(table(mycards$card) == 2) != 1){
    return (0)
  } else{
    p2 = 0  # probability of not getting the second pair.  Keep and mind we have fewer pairing chances
    for(i in c(0:(to_draw -1))){
      p2 = p2 + (
          1 - (((nleft - i) - (nhere +i - 2))/(nleft - i))
        )
    }
    return(p2)
    # return(
    #   1 - (
    #     ((choose(nhere, )^to_draw) * choose(13, to_draw))/
    #       choose(52, to_draw)
    #   )
    # )
  }
}

# mycards1 <- mycards
# mycards2 <- rbind(mycards, flop)
# mycards3 <- rbind(mycards, flop, turn)
# mycards4 <- rbind(mycards, flop, turn, river)

# for (set in list(data.frame(), mycards1, mycards2, mycards3, mycards4)){
#   print(current_prob_of_pair(set))
# }
# for (set in list(data.frame(), mycards1, mycards2, mycards3, mycards4)){
#   print(current_prob_of_two_pair(set))
# }

score_all <- function(game, flop=NA, turn=NA, river=NA, remaining=NA, r=NA){
  s <- data.frame(round = rep(r, length(game$players)), player = c(1:length(game$players)))
  plays = c()
  for(i in c(1:length(thisgame$players))){
    sc <- score(mycards=game$players[[i]], flop=flop, turn=turn, river=river, remaining=NA)
    plays <-c(plays, sc)
  }
  s$score <- plays
  return(s)
}  

score <- function(mycards, flop=NA, turn=NA, river=NA, remaining=NA, verbose=F){
  shown <- rbind(mycards, flop, turn, river)
  shown <- shown[!is.na(shown$card), ]
  shown$who <- ifelse(shown$card %in% mycards$card & shown$suit %in% mycards$suit, "player", "table" )
  partial = FALSE
  if (any(is.na(shown$card))){
    partial = TRUE
    shown <- shown[!is.na(shown$card), ]
  }
  if (verbose) print(shown)
  # figure out how many pairs etc we have
  counts <- table(table(shown$card))
  
  # flush is better than a straight, so we check for flushes first
  flush_suit <- flush(shown)
  straight_cards <- NA
  # if we have a flush, is it a straight flush?
  if (!is.na(flush_suit)){
    straight_cards <- straight(shown[shown$suit == flush_suit, ])
  }
  if (nrow(shown) >= 5 & !is.na(flush_suit) & !is.na(straight_cards)){
    #if (verbose) print("Straight Flush!")
    return("straight_flush")
  } else if ("4" %in% names(counts) ){
    #if (verbose) print("Four of a kind!")
    return("four_kind")
  } else if ("3" %in% names(counts) & "2" %in% names(counts)){
    #if (verbose) print("Full house!")
    return("full_house")
  } else if (nrow(shown) >= 5 & !is.na(flush_suit)){
    #if (verbose) print("Flush!")
    return("flush")
  } else if (nrow(shown) >= 5 & all(!is.na(straight(shown)))){
    #if (verbose) print("Straight")
    return("straight")
  } else if ("3" %in% names(counts) ){
    #if (verbose) print("Three of a kind!")
    return("three_kind")
  } else if ("2" %in% names(counts)){
    if (counts["2"] > 1){
      #if (verbose) print("Two pair!")
      return("two_pair")
    } else {
      #if (verbose) print("Pair!")
      return("pair")
    }
  } else {
    #if (verbose) print(paste(sort(shown$card)[nrow(shown)],  "high!"))
    return("high")
  }
}


thisgame <- deal(ndecks=1, nplayers=4, ncards=2, seed=Sys.time())
str(thisgame)
thisgame
mycards = thisgame$players[[1]]
flop=thisgame$flop
turn=thisgame$turn
river = thisgame$river
n <- score_all(game = thisgame, flop=thisgame$flop, r = 1)
n
score_all(game = thisgame, flop=thisgame$flop, turn=thisgame$turn)
score_all(game = thisgame, flop=thisgame$flop, turn=thisgame$turn, river = thisgame$river)



####################################################################################################
s <- data.frame(round = NA, player = NA, score = NA, ncards=NA)
s <- s[!is.na(s),]
s
for(i in c(1:10000)){
  if (i %% 100 == 0) print(i)
  thisgame <- deal(ndecks=1, nplayers=6, ncards=2, seed=Sys.time())
  thisscore1 <- score_all(game = thisgame,  r=i)
  thisscore1$ncards <-2
  thisscore2 <- score_all(game = thisgame, flop=thisgame$flop, r=i)
  thisscore2$ncards <-5
  thisscore3 <- score_all(game = thisgame, flop=thisgame$flop, turn=thisgame$turn, r=i)
  thisscore3$ncards <-6
  thisscore4 <- score_all(game = thisgame, flop=thisgame$flop, turn=thisgame$turn, river = thisgame$river, r=i)
  thisscore4$ncards <-7
  s = rbind(s, thisscore1, thisscore2, thisscore3, thisscore4)
}

s$score <- factor(s$score, levels = c("straight_flush", "four_kind", "full_house", "flush", "straight", "three_kind", "two_pair","pair", "high"))
plot(table(s[s$ncards==2, "score"]))

res <- s %>% group_by(score, ncards) %>% summarize(n=n()) %>% as.data.frame()
res$probability <- res$n/(6*10000)
ggplot(res, aes(x=score, y=probability)) + 
  geom_bar(stat="identity") + 
  facet_wrap(~ncards, scales="free")

ggplot(res, aes(x=ncards, y=probability)) + 
  geom_line() + 
  facet_wrap(~score, scales="free")


ggplot(s, aes(score)) + geom_bar(stat="count") + facet_wrap(~ncards, scales="free")


####################################################################################################








winners <- data.frame(
  hand = c("straight_flush", "four_kind", "full_house", "flush", "straight", "three_kind", "two_pair","pair", "high"),
  freq = c(
    (choose(10, 1) * choose(4,1)),
    (choose(13, 1) * choose(12,1) * choose(4, 1)),
    (choose(13, 1) * choose(4, 3) * choose(12, 1) * choose(4, 2)),
    (choose(13, 5) * choose(4, 1)),
    (choose(10, 1) * (choose(4, 1) ^ 5)),
    (choose(13, 1) * choose(4, 3) * choose(12, 2) * choose(4, 1)),
    
    (((choose(13, 2) * choose(4, 2)) ^ 2) * (choose(11, 1) * choose(4, 1))),
    (((choose(13, 1) * choose(4, 2))  * (choose(12, 3) * choose(4, 1))) ^ 3),
    (choose(13, 5) - 10) * ((choose(4, 1) ^ 5) - 4)),
  score = c(1280, 640, 320, 160, 80, 40, 20, 10, 1)
           )
winners$prob <- winners$freq / choose(52, 5) 






