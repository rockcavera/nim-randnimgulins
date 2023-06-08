It is a package containing multiple pseudorandom number generators (PRNGs).

The package itself does not have a specific motivation, as I was porting to Nim several generator algorithms in search of one that would adapt to my usage needs, such as speed, quality, period size, etc.

Over time, I ended up porting several algorithms and decided to put them all together in a Nim package so it could be reused by other people.

# Current state of the project
The project is in very early development and everything can be changed without prior notice, considering that I don't have a notion of what I intend to make available in addition to the various algorithms that I have ported.

Therefore, use it with no guarantees of future breakages.

# Install
`nimble install https://github.com/rockcavera/nim-randnimgulins.git`

# Disclaimer

I tried to cite the author of the algorithm in the source code. If any algorithm is without proper citation to its author, please report it.

As far as I know, the algorithms presented here are not subject to patents. However, if any algorithm here has a patent, contact me and I will remove it.
