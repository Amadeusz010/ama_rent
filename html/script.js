let uiEnabled = false;

window.addEventListener("message", function(event) {
    if (event.data.action === "open") {
        uiEnabled = true;
        const container = document.getElementById("container");
        const dragToggle = document.getElementById("drag-toggle");

        container.style.display = "block";

        const savedTop = localStorage.getItem("ui_top");
        const savedLeft = localStorage.getItem("ui_left");
        const savedDrag = localStorage.getItem("drag_enabled");
        const savedColor = localStorage.getItem("ui_color");

        if (savedTop && savedLeft) {
            container.style.top = savedTop + "px";
            container.style.left = savedLeft + "px";
            container.style.transform = "none";
        } else {
            centerUI(container);
        }

        if (savedDrag === "true") {
            dragToggle.checked = true;
            makeDraggable(container, document.getElementById("drag-header"));
        } else {
            dragToggle.checked = false;
        }

        if (savedColor) {
            container.style.backgroundColor = savedColor;
        } else {
            container.style.backgroundColor = "#1e1e1e";
        }

        const list = document.getElementById("vehicle-list");
        list.innerHTML = "";

        const vehicles = event.data.vehicles;
        const itemsPerPage = 4;
        let currentPage = 0;
        const totalPages = Math.ceil(vehicles.length / itemsPerPage);

        function renderPage(page) {
            list.innerHTML = "";
            const start = page * itemsPerPage;
            const end = Math.min(start + itemsPerPage, vehicles.length);
            for (let i = start; i < end; i++) {
                const v = vehicles[i];
                const wrapper = document.createElement("div");
                wrapper.className = "vehicle-item";

                const label = document.createElement("span");
                label.innerText = `${v.label} - $${v.price}`;
                label.className = "vehicle-label";

                const rentButton = document.createElement("button");
                rentButton.innerText = "Rental";
                rentButton.className = "vehicle-button";
                rentButton.onclick = () => {
                    if (!uiEnabled) return;

                    fetch(`https://${GetParentResourceName()}/rentVehicle`, {
                        method: "POST",
                        headers: { "Content-Type": "application/json" },
                        body: JSON.stringify({ vehicle: v.model })
                    }).then(() => {
                        closeUI();
                    });
                };

                wrapper.appendChild(label);
                wrapper.appendChild(rentButton);
                list.appendChild(wrapper);
            }

            document.getElementById("page-up").disabled = (page === 0);
            document.getElementById("page-down").disabled = (page >= totalPages - 1);
        }

        renderPage(currentPage);

        document.getElementById("page-up").onclick = () => {
            if (currentPage > 0) {
                currentPage--;
                renderPage(currentPage);
            }
        };

        document.getElementById("page-down").onclick = () => {
            if (currentPage < totalPages - 1) {
                currentPage++;
                renderPage(currentPage);
            }
        };

        dragToggle.addEventListener("change", function () {
            if (this.checked) {
                makeDraggable(container, document.getElementById("drag-header"));
                localStorage.setItem("drag_enabled", "true");
            } else {
                document.onmousemove = null;
                document.onmouseup = null;
                localStorage.setItem("drag_enabled", "false");
            }
        });

        document.querySelectorAll('.color-circle').forEach(circle => {
            circle.addEventListener('click', () => {
                const color = circle.getAttribute('data-color');
                container.style.backgroundColor = color;
                localStorage.setItem("ui_color", color);
            });
        });

        document.getElementById("reset-btn").addEventListener("click", () => {
            localStorage.removeItem("ui_top");
            localStorage.removeItem("ui_left");
            localStorage.removeItem("drag_enabled");
            localStorage.removeItem("ui_color");

            centerUI(container);
            container.style.backgroundColor = "#1e1e1e";
            dragToggle.checked = false;
            document.onmousemove = null;
            document.onmouseup = null;
            currentPage = 0;
            renderPage(currentPage);
        });
    }
});

function centerUI(container) {
    container.style.top = (window.innerHeight / 2 - container.offsetHeight / 2) + "px";
    container.style.left = (window.innerWidth / 2 - container.offsetWidth / 2) + "px";
    container.style.transform = "none";
}

function closeUI() {
    uiEnabled = false;
    const container = document.getElementById("container");
    container.style.display = "none";

    fetch(`https://${GetParentResourceName()}/close`, {
        method: "POST",
        headers: { "Content-Type": "application/json" }
    });
}

function makeDraggable(el, handle) {
    let pos1 = 0, pos2 = 0, pos3 = 0, pos4 = 0;

    handle.onmousedown = function dragMouseDown(e) {
        const dragToggle = document.getElementById("drag-toggle");
        if (!dragToggle.checked) return;

        e = e || window.event;
        e.preventDefault();

        pos3 = e.clientX;
        pos4 = e.clientY;

        document.onmouseup = closeDragElement;
        document.onmousemove = elementDrag;
    };

    function elementDrag(e) {
        e = e || window.event;
        e.preventDefault();

        pos1 = pos3 - e.clientX;
        pos2 = pos4 - e.clientY;
        pos3 = e.clientX;
        pos4 = e.clientY;

        let newTop = el.offsetTop - pos2;
        let newLeft = el.offsetLeft - pos1;

        const minLeft = 0;
        const minTop = 0;
        const maxLeft = window.innerWidth - el.offsetWidth;
        const maxTop = window.innerHeight - el.offsetHeight;

        newLeft = Math.max(minLeft, Math.min(newLeft, maxLeft));
        newTop = Math.max(minTop, Math.min(newTop, maxTop));

        el.style.top = newTop + "px";
        el.style.left = newLeft + "px";

        localStorage.setItem("ui_top", newTop);
        localStorage.setItem("ui_left", newLeft);
    }

    function closeDragElement() {
        document.onmouseup = null;
        document.onmousemove = null;
    }
}
