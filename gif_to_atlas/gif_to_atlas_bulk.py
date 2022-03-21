#!/usr/bin/python3.10
from PIL import Image
import os
import argparse
import luadata
import math
from threading import Timer
from progressbar import ProgressBar

parser = argparse.ArgumentParser(
    description="convert gif to simple texture atlas")
parser.add_argument("-j",
                    action="store_true",
                    help="just generate data, not atlases")
parser.add_argument("-s", type=int, help="percentage scale factor")

args = parser.parse_args()

gifs = [a for a in os.listdir(".") if a.endswith(".gif")]

bar_len = 0
if not args.j:
    for g in gifs:
        with Image.open(g) as im:
            bar_len += math.ceil(im.n_frames / 12)
else:
    bar_len = len(gifs)

bar = ProgressBar(max_value=bar_len).start()
def update_bar():
    if not bar.value == bar.max_value:
        bar.update()
        Timer(1.0, update_bar).start()
update_bar()

os.system("mkdir -p animations")
for g in gifs:
    bar.update()
    cols = 3
    rows = 4
    scale = args.s or 50
    anim_name = g.replace(".gif", "")
    with Image.open(g) as im:
        w = int(im.width * scale / 100)
        h = int(im.height * scale / 100)
        counter = 0
        atlases = []
        data = {
            "n_frames": im.n_frames,
            "width": w,
            "height": h,
            "cols": cols,
            "rows": rows,
            "durations": [],
            "atlas_width": w * cols,
            "atlas_height": h * rows,
            "animated": im.n_frames > 1
        }
        for i in range(im.n_frames):
            if counter == 0:
                atlases.append(Image.new(
                    "RGB", (w * cols, h * rows)))  # create new atlas if needed

            im.seek(i)  # go to next frame

            data["durations"].append(
                im.info["duration"])  # update duration info

            frame = Image.new(
                "RGB",
                (im.width, im.height))  # create image to use for scaling
            frame.paste(im)  # paste current frame to scalable copy
            frame.thumbnail((w, h), Image.ANTIALIAS)  # scale the frame

            atlases[-1].paste(frame, (counter % cols * w, counter // cols *
                                      h))  # paste into current atlas
            counter += 1  # increment counter
            counter %= cols * rows  # reset counter if needed
        data["n_atlases"] = len(atlases)
        luadata.write(f"animations/{anim_name}.lua", data, indent="\t")
        pil_output = anim_name + ".png"
        if not args.j:
            for i, atl in enumerate(atlases):
                output_tex = g.replace('.gif', f'_{i + 1}.t3x')
                if not output_tex in os.listdir("animations"):
                    atl.save(pil_output)  # save atlas to png
                    cmd = f"tex3ds {pil_output} -o animations/{output_tex} > /dev/null"  # generate t3x file, 1 indexed because lua is stupid
                    os.system(cmd)
                    os.system(f"rm {pil_output}")
                bar.value += 1
        else:
            bar.value += 1
