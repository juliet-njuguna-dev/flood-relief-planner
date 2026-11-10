
// Connect the Run Planner button
document.getElementById("run-button").addEventListener("click", runPlanner);


// Main function that communicates with the Lisp backend
async function runPlanner() {

    const scenario = document.getElementById("scenario").value;
    const algorithm = document.getElementById("algorithm").value;

    const status = document.getElementById("result-status");

    const bfsCard = document.getElementById("bfs-card");
    const astarCard = document.getElementById("astar-card");
    const comparisonPanel = document.getElementById("comparison-panel");

    status.textContent = "Running planner...";

    bfsCard.style.display = "none";
    astarCard.style.display = "none";
    comparisonPanel.style.display = "none";

    try {

        const response = await fetch(
            `/run?scenario=${scenario}&algorithm=${algorithm}`
        );

        const data = await response.json();

        if (!response.ok || data.error) {
            throw new Error(data.error || "Request failed.");
        }

        // Display individual algorithm results
        data.results.forEach(function(result) {
            displayResult(result);
        });

        // Show comparison only when both algorithms were requested
        if (algorithm === "both" && data.results.length === 2) {
            compareAlgorithms(data.results[0], data.results[1]);
        }

        const successfulResults = data.results.filter(function(result) {
            return result.found && result.verified;
        });

        if (successfulResults.length > 0) {
            status.textContent = "Valid delivery plan found.";
        } else {
            status.textContent =
                "Search completed: no valid delivery plan found.";
        }

    } catch (error) {

        console.error("Planner error:", error);
        status.textContent = "Error: " + error.message;

    }
}


// Display the results of either BFS or A*
function displayResult(result) {

    const prefix = result.algorithm;

    const card = document.getElementById(prefix + "-card");
    const planOutput = document.getElementById(prefix + "-plan");

    card.style.display = "block";

    // Display statistics
    document.getElementById(prefix + "-length").textContent =
        result.found ? result.plan_length : "No solution";

    document.getElementById(prefix + "-cost").textContent =
    result.found ? result.total_cost : "--";

    document.getElementById(prefix + "-expanded").textContent =
        result.expanded;

    document.getElementById(prefix + "-generated").textContent =
        result.generated;

    document.getElementById(prefix + "-time").textContent =
        result.time_ms.toFixed(3) + " ms";

    // Display verification status
    if (!result.found) {
        document.getElementById(prefix + "-status").textContent =
            "No solution found";
    } else if (result.verified) {
        document.getElementById(prefix + "-status").textContent =
            "Plan verified";
    } else {
        document.getElementById(prefix + "-status").textContent =
            "Verification failed";
    }

    // Clear previous delivery plan
    planOutput.innerHTML = "";

    if (result.found && result.verified) {

        result.plan.forEach(function(action, index) {

            const step = document.createElement("div");

            step.className = "plan-step";
            step.textContent = (index + 1) + ". " + action;

            planOutput.appendChild(step);

        });

    } else if (!result.found) {

        planOutput.textContent =
            "No delivery plan could be generated. The destination may be unreachable.";

    } else {

        planOutput.textContent =
            "A plan was generated, but it did not pass verification.";

    }
}


// Compare BFS and A* performance
function compareAlgorithms(bfs, astar) {

    const panel = document.getElementById("comparison-panel");

    panel.style.display = "block";

    // Compare expanded nodes
    let nodeWinner;

    if (bfs.expanded < astar.expanded) {
        nodeWinner = "BFS";
    } else if (astar.expanded < bfs.expanded) {
        nodeWinner = "A*";
    } else {
        nodeWinner = "Tie";
    }

    // Compare execution time
    let timeWinner;

    if (bfs.time_ms < astar.time_ms) {
        timeWinner = "BFS";
    } else if (astar.time_ms < bfs.time_ms) {
        timeWinner = "A*";
    } else {
        timeWinner = "Tie";
    }

    // Compare plan lengths
    let planComparison;

    if (bfs.found && astar.found) {

        if (bfs.plan_length === astar.plan_length) {
            planComparison = "Equal";
        } else if (bfs.plan_length < astar.plan_length) {
            planComparison = "BFS shorter";
        } else {
            planComparison = "A* shorter";
        }

    } else if (!bfs.found && !astar.found) {

        planComparison = "Neither found a plan";

    } else {

        planComparison = "Different outcomes";

    }

    document.getElementById("node-winner").textContent = nodeWinner;
    document.getElementById("time-winner").textContent = timeWinner;
    document.getElementById("plan-comparison").textContent = planComparison;

    // Compare total plan costs
let costWinner;

if (bfs.found && astar.found) {

    if (bfs.total_cost < astar.total_cost) {
        costWinner = "BFS";
    } else if (astar.total_cost < bfs.total_cost) {
        costWinner = "A*";
    } else {
        costWinner = "Tie";
    }

} else {
    costWinner = "Not comparable";
}

document.getElementById("cost-winner").textContent = costWinner;

    // Provide a written summary
    const summary = document.getElementById("comparison-summary");

    summary.textContent =
    "BFS expanded " + bfs.expanded +
    " nodes and A* expanded " + astar.expanded +
    " nodes. BFS took " + bfs.time_ms.toFixed(3) +
    " ms, while A* took " + astar.time_ms.toFixed(3) +
    " ms. Plan length: " + planComparison +
    ". Total cost: BFS = " + bfs.total_cost +
    ", A* = " + astar.total_cost + ".";
}
