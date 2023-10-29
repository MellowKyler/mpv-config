import sys
import subprocess
from guessit import guessit

def get_title(filename):
    # Given a filename (as passed from mpv) this function
    # uses guessit to determine relevant properties.

    # Use guessit to get as much information as we can
    g = guessit(filename)

    # Dump the info to the console for debugging purposes
    print(g)
    
    # Get the name of the anime from the results (hopefully)
    return g["title"]

if __name__ == "__main__":
    try:
        title = get_title(sys.argv[1])
        # return_lua = 'return_guessit_title(' + title + ')'
        # subprocess.check_output(['lua', '-l', '/home/kyler/.config/mpv/scripts/screenshot.lua', '-e', return_lua])
        subprocess.run('lua', '/home/kyler/.config/mpv/scripts/screenshot.lua', 'return_guessit_title', title)
        # lua /home/kyler/.config/mpv/scripts/screenshot.lua calc 2
    except Exception as e:
        print("ERROR: {}".format(e))
        sys.exit(1)