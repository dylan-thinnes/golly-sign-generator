import cv2
red = cv2.imread("red.ppm")
green = cv2.imread("green.ppm")
blue = cv2.imread("blue.ppm")
cv2.imwrite("out.ppm", cv2.merge((blue[:,:,1], green[:,:,1], red[:,:,1])))
