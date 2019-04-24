# SP Device

# General structure:
# 1. Present a sentence to visual buffer
# 2. Run model until it stops
# 3. Present a picture to visual buffer
# 4. Run model until it stops
# 5. Record structure used.


#import actr

def parse_log(fle):
    """Parses a log and extracts data"""
    f = open(fle)
    lines = f.readlines()[1:]
    N = len(lines)
    tokens = [x.split(",") for x in lines]
    selected = [[x[5], x[4]] for x in tokens]
    sentences = [x[7] for x in tokens]
    tokenized = [sentence.split() for sentence in sentences]
    nouns = [[tokens[1], tokens[-1]] for tokens in tokenized]
    final = [selected[j] + nouns[j] + [sentences[j]] for j in range(N)]
    return final

