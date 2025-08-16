# Project Overview
This project analyzes NBA Player of the Week (POTW) awards from 1979 to 2020 to uncover trends, correlations, and archetypes among recipients.  
Using a custom SQL data warehouse, cleaned CSV datasets, and statistical analysis, the project examines player attributes, team dynamics, and league evolution to define the profile of the “ideal” NBA player.

# Key Objectives
- Identify trends in Player of the Week awards across players, teams, and seasons.  
- Explore how age, height, weight, and draft year correlate with POTW success.  
- Assess the influence of team market size and pre-draft background.  
- Establish the data-driven archetype of an elite NBA player.

# Methodology

## Data Engineering
- Built a SQL data warehouse with a fact/dimension schema:contentReference[oaicite:0]{index=0}.  
- Cleaned team name inconsistencies (*New Jersey Nets → Brooklyn Nets*).  
- Standardized dates and resolved missing values.  
- Created dimension tables (Players, Teams, Conferences, Seasons, Positions).  

## Data Visualization
- **Awards by Position** – Distribution of POTW by position.  
- **Top Teams** – Teams with the most POTW winners.  
- **Age vs. Awards** – Identified peak performance at age 25.  
- **Height vs. Awards** – Most common height range: 6’6”–6’9”.  
- **Player Dominance** – LeBron James with nearly 2× more awards than any other player:contentReference[oaicite:1]{index=1}.  

# Major Findings
- **Player Dominance**: LeBron James leads POTW history by a wide margin.  
- **Team Success**: Big-market teams dominate, but Oklahoma City Thunder stand out despite being a small-market team.  
- **Peak Age**: The prime POTW age is 25, not 27–28 as commonly assumed.  
- **Height Stability**: Despite taller guards entering the league, the archetype winner remains between 6’6”–6’9”.  

# Backstory
As a lifelong NBA fan, I wanted to merge my love for basketball with data analytics. Inspired by Jeremy Lin’s *Linsanity* and my admiration for LeBron James, I set out to uncover what makes a player truly exceptional.  
This project was both an academic challenge and a personal step toward a career in sports analytics:contentReference[oaicite:2]{index=2}.

# Tech Stack
- **SQL Server** – Data warehouse design & ETL  
- **Excel / CSV** – Data sources & preprocessing  
- **Visualization Tools** – Charts and plots for insights  
- **Docx Report** – Final academic write-up  

## Conclusion
This project provides a data-driven framework for understanding NBA excellence.  
It highlights the impact of superstar dominance, market influence, age, and physical archetypes in shaping the league’s Player of the Week awards. 


