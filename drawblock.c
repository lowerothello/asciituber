#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <dirent.h>
#include <ctype.h>

#define STR_LEN 1024

int min(int a, int b) {
	return (a > b) ? b : a;
}

int linecount(char filename[], char buffer[STR_LEN]) {
	FILE *fp = fopen(filename, "r");
	if (fp == NULL) {
		printf("Failed to open file %s for reading\n", filename);
		return 1;
	}

	int lc = 0;
	while (fgets(buffer, STR_LEN, fp))
		lc++;

	fclose(fp);

	return lc;
}

int main(int argc, char *argv[]) {
	if (argv[1] == NULL) {
		printf("Missing args\n");
		return 1;
	}

	char buffer[STR_LEN];
	char path[STR_LEN];
	char dirpath[STR_LEN];

	/* CONFIG FILE */
	strcpy(path, argv[1]);
	FILE *config = fopen(strcat(path, "/config"), "r");
	if (config == NULL) {
		printf("Failed to open config file\n");
		return 1;
	}

	/* there's always the same amount of fields to read */
	fgets(buffer, STR_LEN, config); int row = atoi(buffer);
	fgets(buffer, STR_LEN, config); int col = atoi(buffer);
	fgets(buffer, STR_LEN, config); int filmheight = atoi(buffer);

	int X = atoi(getenv("X"));
	int Y = atoi(getenv("Y"));
	int H = atoi(getenv("H"));
	int W = atoi(getenv("W"));
	int MODX = atoi(getenv("MODX"));
	int MODY = atoi(getenv("MODY"));
	int trimwidth;
	int i;
	int filmframecount;
	int drawnlines;
	int processedlines;

	int fg;
	int bg;
	int attr;
	int filmtime;
	int filmshownframe;

	/* completely off screen checks */
	int lineno = row + Y + MODY;
	if (lineno > H) return 0;
	if (col + X + MODX > W) return 0;

	fclose(config);

	/* LAYER FILES */
	struct dirent *ep;
	strcpy(dirpath, argv[1]);
	/* shouldn't fail if the config file can be loaded */
	DIR *dp = opendir(dirpath);
	FILE *layer;

	/* iterate over numerated files (the layers) */
	while (ep = readdir(dp)) {
		if (isdigit(ep->d_name[0])) {
			lineno = row + Y + MODY; /* reset lineno */
			int xpos = X + MODX + col;
			int ltrim = 0;
			if (xpos <= 0)
				ltrim = xpos * -1 + 1;

			strcpy(path, argv[1]);
			layer = fopen(strcat(strcat(path, "/"), ep->d_name), "r");
			if (layer == NULL) {
				printf("Failed to open layer\n");
				return 1;
			}

			/* get the film frame count */
			if (filmheight > 0) {
				filmframecount = (linecount(path, buffer) - 5) / filmheight;
			} else {
				filmframecount = 1;
			}

			/* read the layer's header */
			fgets(buffer, STR_LEN, layer); fg = atoi(buffer);
			fgets(buffer, STR_LEN, layer); bg = atoi(buffer);
			fgets(buffer, STR_LEN, layer); attr = atoi(buffer);
			fgets(buffer, STR_LEN, layer); filmtime = atoi(buffer);
			/* filmshownframe is more complex than the above few */
			fgets(buffer, STR_LEN, layer);
			if (argc < 2 || filmtime <= 0)
				filmshownframe = 1;
			else {
				switch (atoi(buffer)) {
					case 0: filmshownframe = (min(atoi(argv[2]), filmframecount * filmtime)) / filmtime;
					case 1: filmshownframe = (atoi(argv[2]) % (filmframecount * filmtime)) / filmtime;
				}
			}

			/* reset state */
			drawnlines = 0;
			processedlines = 0;
			
			while (fgets(buffer, STR_LEN, layer)) {
				/* burn through lines until the wanted frame is queued */
				processedlines++;
				if (filmshownframe >= 1 && processedlines <= (filmshownframe * filmheight)) continue;

				if (lineno >= H) break; /* finish before lines are drawn off screen */
				if (lineno >= 1) { /* start when the lines are being drawn on screen */
					/* stop after drawing a full frame */
					drawnlines++;
					if (filmheight > 0 && drawnlines > filmheight) break;

					/* trim off the left side */
					if (ltrim > 0) memmove(buffer, buffer+ltrim, strlen(buffer));
					if (strlen(buffer) > 0) {
						/* for trimming off the right side later */
						trimwidth = min(strlen(buffer) + ltrim, W - col - MODX);
						/* width mod in case we're trimming off the left side
						magic number 1 is cos the xpos is 0 instead of 1 */
						if (xpos < 0) trimwidth = trimwidth + xpos - 1;

						// set text formatting opts
						printf("\033[%dm\033[38;5;%dm\033[48;5;%dm", attr, fg, bg);
						// draw the block
						for (i = 0; i < min(strlen(buffer), trimwidth); i++) {
							if (buffer[i] != ' ')
								printf("\033[%d;%dH%c", lineno, xpos + i, buffer[i]);
						}
						// unset text formatting opt
						printf("\033[m");
					}
				}
				lineno++;
			}
		}
	}
	closedir(dp);

	return 0;
}
