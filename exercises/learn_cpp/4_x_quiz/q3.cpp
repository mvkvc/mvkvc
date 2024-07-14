// Write a short program to simulate a ball being dropped off of a tower. To start, the user should be asked for the height of the tower in meters. Assume normal gravity (9.8 m/s2), and that the ball has no initial velocity (the ball is not moving to start). Have the program output the height of the ball above the ground after 0, 1, 2, 3, 4, and 5 seconds. The ball should not go underneath the ground (height 0).

// Use a function to calculate the height of the ball after x seconds. The function can calculate how far the ball has fallen after x seconds using the following formula: distance fallen = gravity_constant * x_seconds2 / 2

// Expected output:

// Enter the height of the tower in meters: 100
// At 0 seconds, the ball is at height: 100 meters
// At 1 seconds, the ball is at height: 95.1 meters
// At 2 seconds, the ball is at height: 80.4 meters
// At 3 seconds, the ball is at height: 55.9 meters
// At 4 seconds, the ball is at height: 21.6 meters
// At 5 seconds, the ball is on the ground.

#include <iostream>
#include <iomanip> 
#include <cmath>

double getTowerHeight() {
    double gravity{9.8};
    std::cout << "Enter a height for a ball to be dropped: ";
    double height{};
    std::cin >> height;

    return height;
}

double calcTravelled( double height, int seconds) {
    double gravity{9.8};
    double fallDistance { gravity * (seconds * seconds ) / 2.0 };

    return fallDistance;
}

void outputStatus(int time_s, double height) {
    if (height > 0) {
        std::cout << "At " << time_s << " seconds, the ball is at height: " << height << " meters." << "\n";
    } else {
        std::cout << "At " << time_s << " seconds, the ball is on the ground." << "\n";
    }
}

int main() {
    double height{ getTowerHeight() };

    double remainingHeight{height};
    int secondsElapsed{0};

    outputStatus(secondsElapsed, remainingHeight);
    while (remainingHeight > 0) {
        secondsElapsed++;
        remainingHeight = height - calcTravelled(height, secondsElapsed);

        outputStatus(secondsElapsed, remainingHeight);
    }
}
