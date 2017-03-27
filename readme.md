#@echoebook

@echoebook is an ebook style Twitter bot whose personality is based on the accounts it follows. As @echoebook follows other accounts, its personality will change and should emulate the crowds behaviors.

@echoebook writes tweets by consuming the entire history (corpus) of the accounts it follows. It uses that data to generate a model that maps the probability of one word following another. Then using that probability model, a random number generator, and few other indicators, it writes new tweets and replies when communicated with.

Sometimes the tweets are pretty coherent; other times they aren't. Either way, it's usually entertaining.

The process is based on the mathematical principles of Markov Chains. The process is not dissimilar to how autocorrect/suggest works on your smartphone.

This bot leans a lot on the work of the [mispy/twitter_ebooks](https://github.com/mispy/twitter_ebooks) framework.